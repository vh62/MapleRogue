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
