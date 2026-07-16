import Foundation

/// Everything that persists between runs. Pure domain, Codable.
struct PlayerProfile: Codable, Equatable {
    var mesos: Int = 0
    var gems: Int = 0
    var bestRoomCleared: Int = 0
    var runsCompleted: Int = 0
    var selectedClassID: String = "dark_knight"
    var unlockedClassIDs: [String] = ["dark_knight"]
    var gearInventory: [GearItem] = []
    var gearPresets: [GearPreset] = [GearPreset(), GearPreset(), GearPreset()]
    var activePresetIndex: Int = 0
    var level: Int = 1
    var xp: Int = 0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case mesos, gems, bestRoomCleared, runsCompleted, selectedClassID,
             unlockedClassIDs, gearInventory, gearPresets, activePresetIndex,
             level, xp
        case legacyWeapon = "weapon"   // pre-merge starforce weapon, read-only
    }

    /// Shape of the retired standalone starforce weapon, kept only to
    /// migrate its stars into the gear system.
    private struct LegacyWeapon: Codable {
        var stars: Int
    }

    /// Tolerant decoding: fields added in later app versions fall back to
    /// defaults instead of nuking the whole saved profile.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mesos = try container.decodeIfPresent(Int.self, forKey: .mesos) ?? 0
        gems = try container.decodeIfPresent(Int.self, forKey: .gems) ?? 0
        bestRoomCleared = try container.decodeIfPresent(Int.self, forKey: .bestRoomCleared) ?? 0
        runsCompleted = try container.decodeIfPresent(Int.self, forKey: .runsCompleted) ?? 0
        selectedClassID = try container.decodeIfPresent(String.self, forKey: .selectedClassID) ?? "dark_knight"
        unlockedClassIDs = try container.decodeIfPresent([String].self, forKey: .unlockedClassIDs) ?? ["dark_knight"]
        // Older saves have no gear — seed a starter set on first load.
        gearInventory = try container.decodeIfPresent([GearItem].self, forKey: .gearInventory)
            ?? GearItem.starterInventory()
        gearPresets = try container.decodeIfPresent([GearPreset].self, forKey: .gearPresets)
            ?? [GearPreset(), GearPreset(), GearPreset()]
        activePresetIndex = try container.decodeIfPresent(Int.self, forKey: .activePresetIndex) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0

        // Migration: transplant the legacy weapon's stars onto a weapon-slot
        // gear item so nobody loses starforce progress.
        if let legacy = try? container.decodeIfPresent(LegacyWeapon.self, forKey: .legacyWeapon),
           legacy.stars > 0 {
            let migrated = GearItem(slot: .weapon, rarity: .rare, level: 1, stars: legacy.stars)
            gearInventory.append(migrated)
            gearPresets[min(activePresetIndex, gearPresets.count - 1)].equip(migrated)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mesos, forKey: .mesos)
        try container.encode(gems, forKey: .gems)
        try container.encode(bestRoomCleared, forKey: .bestRoomCleared)
        try container.encode(runsCompleted, forKey: .runsCompleted)
        try container.encode(selectedClassID, forKey: .selectedClassID)
        try container.encode(unlockedClassIDs, forKey: .unlockedClassIDs)
        try container.encode(gearInventory, forKey: .gearInventory)
        try container.encode(gearPresets, forKey: .gearPresets)
        try container.encode(activePresetIndex, forKey: .activePresetIndex)
        try container.encode(level, forKey: .level)
        try container.encode(xp, forKey: .xp)
        // legacyWeapon intentionally not encoded — migration is one-way.
    }

    static func newPlayer() -> PlayerProfile {
        var profile = PlayerProfile()
        profile.gearInventory = GearItem.starterInventory()
        return profile
    }
}

/// Storage abstraction so persistence is swappable (and testable with a fake).
protocol ProfileStore {
    func load() -> PlayerProfile?
    func save(_ profile: PlayerProfile)
}

/// JSON blob in UserDefaults — right-sized for a single small profile.
/// Swap for SwiftData if the model grows (inventory lists, multiple heroes).
struct UserDefaultsProfileStore: ProfileStore {

    private let key = "maplerogue.playerProfile"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerProfile? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlayerProfile.self, from: data)
    }

    func save(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: key)
    }
}
