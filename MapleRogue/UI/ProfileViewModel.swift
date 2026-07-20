import Foundation
import Combine

/// Owns the persistent player profile. Lives at the app root and is shared
/// by the lobby (currencies, forge, progress) and the game (banking runs).
final class ProfileViewModel: ObservableObject {

    @Published private(set) var profile: PlayerProfile

    private let store: ProfileStore
    private var starforce = StarforceSystem()
    private var chests = ChestSystem()

    init(store: ProfileStore = UserDefaultsProfileStore()) {
        self.store = store
        self.profile = store.load() ?? .newPlayer()
    }

    private func persist() {
        store.save(profile)
    }

    // MARK: - Run results

    /// Banks a run and returns how many account levels were gained.
    @discardableResult
    func bankRun(goldEarned: Int, xpEarned: Int, roomReached: Int, victory: Bool) -> Int {
        profile.mesos += goldEarned
        profile.bestRoomCleared = max(profile.bestRoomCleared, roomReached)
        if victory {
            profile.runsCompleted += 1
            profile.gems += 10   // boss-kill gem trickle keeps the premium loop alive for F2P
        }

        let result = LevelCurve.apply(xp: xpEarned, toLevel: profile.level, xp: profile.xp)
        profile.level = result.level
        profile.xp = result.xp

        persist()
        return result.levelsGained
    }

    var xpToNextLevel: Int {
        LevelCurve.xpToNext(from: profile.level)
    }

    var xpProgress: Double {
        Double(profile.xp) / Double(max(1, xpToNextLevel))
    }

    // MARK: - Starforce (Forge tab)

    /// The Forge works on the weapon equipped in the active preset.
    var forgeTarget: GearItem? {
        equippedItem(in: .weapon)
    }

    var enhanceCost: Int? {
        guard let target = forgeTarget, target.stars < GearItem.maxStars else { return nil }
        return StarforceTable.cost(forStar: target.stars)
    }

    /// Attempts an enhancement on the equipped weapon.
    /// Returns nil if no weapon equipped, maxed, or unaffordable.
    func attemptStarforce() -> StarforceOutcome? {
        guard var target = forgeTarget,
              let cost = enhanceCost,
              profile.mesos >= cost else { return nil }

        profile.mesos -= cost
        let outcome = starforce.attempt(on: &target)

        switch outcome {
        case .success, .fail:
            if let index = profile.gearInventory.firstIndex(where: { $0.id == target.id }) {
                profile.gearInventory[index] = target
            }
        case .destroyed:
            profile.gearInventory.removeAll { $0.id == target.id }
            for index in profile.gearPresets.indices {
                profile.gearPresets[index].remove(itemID: target.id)
            }
        case nil:
            break
        }
        persist()
        return outcome
    }

    #if DEBUG
    /// Dev-only: grants mesos, gems, and levels for feature testing.
    /// Compiled out of release builds.
    func debugBoost() {
        profile.mesos += 5000
        profile.gems += 200
        let result = LevelCurve.apply(xp: 3000, toLevel: profile.level, xp: profile.xp)
        profile.level = result.level
        profile.xp = result.xp
        persist()
    }
    #endif

    // MARK: - Feature gates (unlock by account level)

    enum FeatureGate: Int {
        case forge = 3
        case presets = 5
        case premiumChest = 6

        var label: String { "Lv \(rawValue)" }
    }

    func isUnlocked(_ gate: FeatureGate) -> Bool {
        profile.level >= gate.rawValue
    }

    // MARK: - Shop

    /// Opens a chest if affordable; the item goes straight to the inventory.
    func openChest(_ chest: ChestType) -> GearItem? {
        let cost = chest.cost
        guard profile.mesos >= cost.mesos, profile.gems >= cost.gems else { return nil }
        profile.mesos -= cost.mesos
        profile.gems -= cost.gems

        let item = chests.open(chest)
        profile.gearInventory.append(item)
        persist()
        return item
    }

    func canAfford(_ chest: ChestType) -> Bool {
        profile.mesos >= chest.cost.mesos && profile.gems >= chest.cost.gems
    }

    /// Boss kill reward: a free premium-odds gear roll into the inventory.
    func rollVictoryLoot() -> GearItem {
        let item = chests.open(.premium)
        profile.gearInventory.append(item)
        persist()
        return item
    }

    // MARK: - Classes (Character tab)

    var selectedClass: HeroClass {
        ClassRegistry.byID(profile.selectedClassID)
    }

    func isUnlocked(_ heroClass: HeroClass) -> Bool {
        profile.unlockedClassIDs.contains(heroClass.id)
    }

    func selectClass(_ heroClass: HeroClass) {
        guard isUnlocked(heroClass) else { return }
        profile.selectedClassID = heroClass.id
        persist()
    }

    /// Unlocks with mesos and selects it. No-op if unaffordable or owned.
    func unlockClass(_ heroClass: HeroClass) {
        guard !isUnlocked(heroClass), profile.mesos >= heroClass.unlockCost else { return }
        profile.mesos -= heroClass.unlockCost
        profile.unlockedClassIDs.append(heroClass.id)
        profile.selectedClassID = heroClass.id
        persist()
    }

    // MARK: - Gear (Character tab)

    var activePreset: GearPreset {
        profile.gearPresets[safePresetIndex]
    }

    private var safePresetIndex: Int {
        min(max(profile.activePresetIndex, 0), profile.gearPresets.count - 1)
    }

    func item(withID id: UUID) -> GearItem? {
        profile.gearInventory.first { $0.id == id }
    }

    func equippedItem(in slot: GearSlot) -> GearItem? {
        activePreset.itemID(for: slot).flatMap(item(withID:))
    }

    var equippedItems: [GearItem] {
        GearSlot.allCases.compactMap(equippedItem(in:))
    }

    /// Percent ATK from all equipped gear (stacks with weapon starforce).
    var gearAtkPercent: Int {
        equippedItems.reduce(0) { $0 + $1.atkPercent }
    }

    /// Flat HP from all equipped gear.
    var gearBonusHP: Int {
        equippedItems.reduce(0) { $0 + $1.bonusHP }
    }

    /// Full meta-progression contribution to a run, cube potentials included.
    var heroBuild: HeroBuild {
        let items = equippedItems
        return HeroBuild(
            atkPercent: items.reduce(0) { $0 + $1.atkPercent },
            bonusHP: items.reduce(0) { $0 + $1.bonusHP },
            critRatePercent: items.reduce(0) { $0 + $1.potentialTotal(.critRate) },
            critDmgPercent: items.reduce(0) { $0 + $1.potentialTotal(.critDmg) },
            moveSpeedPercent: items.reduce(0) { $0 + $1.potentialTotal(.moveSpeed) })
    }

    // MARK: - Cubes

    private var cubeSystem = CubeSystem()

    func canAffordCube(_ cube: CubeType) -> Bool {
        profile.mesos >= cube.costMesos && profile.gems >= cube.costGems
    }

    /// Uses a cube on an owned item. Returns nil if not owned or unaffordable.
    func useCube(_ cube: CubeType, on itemID: UUID) -> CubeSystem.Result? {
        guard let index = profile.gearInventory.firstIndex(where: { $0.id == itemID }),
              canAffordCube(cube) else { return nil }

        profile.mesos -= cube.costMesos
        profile.gems -= cube.costGems
        let result = cubeSystem.use(cube, on: &profile.gearInventory[index])
        persist()
        return result
    }

    /// Premium roll awaiting a keep-or-replace decision.
    /// In-memory only: if the app dies mid-choice, the old lines survive.
    @Published private(set) var pendingCube: (itemID: UUID, roll: CubeSystem.PendingRoll)?

    /// Premium (Black Cube) use: pays, rolls, and either auto-applies
    /// (rank-up / empty item) or parks the roll for the player's decision.
    func usePremiumCube(on itemID: UUID) {
        let cube = CubeType.premium
        guard let index = profile.gearInventory.firstIndex(where: { $0.id == itemID }),
              canAffordCube(cube) else { return }

        profile.mesos -= cube.costMesos
        profile.gems -= cube.costGems
        let roll = cubeSystem.roll(cube, on: &profile.gearInventory[index])
        persist()   // pity/rank/payment always commit immediately

        pendingCube = roll.autoApplied ? nil : (itemID, roll)
        if roll.autoApplied {
            lastAutoAppliedRoll = roll
        }
    }

    /// Auto-applied premium result (rank-up), for UI celebration.
    @Published private(set) var lastAutoAppliedRoll: CubeSystem.PendingRoll?

    /// Resolves the parked premium roll.
    func resolvePendingCube(takeNew: Bool) {
        guard let pending = pendingCube else { return }
        if takeNew,
           let index = profile.gearInventory.firstIndex(where: { $0.id == pending.itemID }) {
            profile.gearInventory[index].setPotential(pending.roll.newLines)
            persist()
        }
        pendingCube = nil
    }

    func switchPreset(to index: Int) {
        guard profile.gearPresets.indices.contains(index) else { return }
        profile.activePresetIndex = index
        persist()
    }

    func canWear(_ item: GearItem) -> Bool {
        profile.level >= item.requiredLevel
    }

    /// Equips only if the account level meets the item's requirement.
    @discardableResult
    func equip(_ item: GearItem) -> Bool {
        guard canWear(item) else { return false }
        profile.gearPresets[safePresetIndex].equip(item)
        persist()
        return true
    }

    /// Upgrades an owned item with mesos. Returns false if unaffordable.
    @discardableResult
    func upgradeGear(_ item: GearItem) -> Bool {
        guard let index = profile.gearInventory.firstIndex(where: { $0.id == item.id }),
              profile.mesos >= profile.gearInventory[index].upgradeCost else { return false }
        profile.mesos -= profile.gearInventory[index].upgradeCost
        profile.gearInventory[index].upgrade()
        persist()
        return true
    }

    let replacementWeaponCost = 100

    /// Buys and equips a basic weapon when the slot is empty (post-destroy).
    func buyReplacementWeapon() {
        guard forgeTarget == nil, profile.mesos >= replacementWeaponCost else { return }
        profile.mesos -= replacementWeaponCost
        let weapon = GearItem(slot: .weapon, rarity: .common, level: 1)
        profile.gearInventory.append(weapon)
        profile.gearPresets[safePresetIndex].equip(weapon)
        persist()
    }
}
