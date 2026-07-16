import Foundation

/// The six equippable slots (design: Character Tab.dc.html).
enum GearSlot: String, Codable, CaseIterable {
    case weapon = "AXE"
    case ring = "RING"
    case cape = "CAPE"
    case helm = "HELM"
    case mask = "MASK"
    case boots = "BOOT"
}

enum GearRarity: String, Codable, CaseIterable, Comparable {
    case common, rare, epic, legendary

    static func < (lhs: GearRarity, rhs: GearRarity) -> Bool {
        order(lhs) < order(rhs)
    }
    private static func order(_ r: GearRarity) -> Int {
        switch r {
        case .common: 0
        case .rare: 1
        case .epic: 2
        case .legendary: 3
        }
    }

    var displayName: String { rawValue.capitalized }

    /// Stat multiplier per level.
    var statMultiplier: Int {
        switch self {
        case .common: 1
        case .rare: 2
        case .epic: 3
        case .legendary: 5
        }
    }
}

/// One piece of gear in the inventory. Stats derive from rarity × level,
/// plus starforce stars (high-risk enhancement, see Starforce.swift).
struct GearItem: Codable, Equatable, Identifiable {

    static let maxStars = 20

    let id: UUID
    let slot: GearSlot
    let rarity: GearRarity
    private(set) var level: Int
    private(set) var stars: Int

    init(id: UUID = UUID(), slot: GearSlot, rarity: GearRarity, level: Int = 1, stars: Int = 0) {
        self.id = id
        self.slot = slot
        self.rarity = rarity
        self.level = level
        self.stars = stars
    }

    /// Tolerant decoding: `stars` was added after gear shipped to saves.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        slot = try container.decode(GearSlot.self, forKey: .slot)
        rarity = try container.decode(GearRarity.self, forKey: .rarity)
        level = try container.decode(Int.self, forKey: .level)
        stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
    }

    var name: String {
        let names: [GearSlot: String] = [
            .weapon: "Emberfang Axe", .ring: "Tidebound Ring", .cape: "Skywisp Cape",
            .helm: "Acorn Helm", .mask: "Whisker Mask", .boots: "Puddle Boots",
        ]
        return names[slot] ?? slot.rawValue
    }

    /// Account level required to equip. Item level drives it; higher
    /// rarities are aspirational (legendary +5). Requirement is checked at
    /// equip time only — upgrading an equipped item never unequips it.
    var requiredLevel: Int {
        let rarityBump: Int
        switch rarity {
        case .common: rarityBump = 0
        case .rare: rarityBump = 1
        case .epic: rarityBump = 2
        case .legendary: rarityBump = 5
        }
        return Swift.max(1, level - 2 + rarityBump)
    }

    /// Percent added to base attack while equipped (level + starforce).
    var atkPercent: Int { level * rarity.statMultiplier / 2 + starforceAtkPercent }
    /// +8% attack per star.
    var starforceAtkPercent: Int { stars * 8 }
    /// Flat HP added while equipped.
    var bonusHP: Int { level * rarity.statMultiplier }

    var upgradeCost: Int { 15 * level * rarity.statMultiplier }

    mutating func upgrade() {
        level += 1
    }

    mutating func addStar() {
        stars = Swift.min(stars + 1, Self.maxStars)
    }

    /// A modest random starter set so new profiles have something to equip.
    static func starterInventory() -> [GearItem] {
        let rarities: [GearRarity] = [.common, .common, .common, .rare, .rare, .epic]
        var items: [GearItem] = []
        for slot in GearSlot.allCases {
            // Low levels keep every starter item wearable at account level 1.
            items.append(GearItem(slot: slot,
                                  rarity: rarities.randomElement() ?? .common,
                                  level: Int.random(in: 1...2)))
        }
        // A few extras so the grid shows choice, not just one per slot.
        for _ in 0..<4 {
            items.append(GearItem(slot: GearSlot.allCases.randomElement() ?? .ring,
                                  rarity: Bool.random() ? .common : .rare,
                                  level: Int.random(in: 1...4)))
        }
        return items
    }
}

/// One loadout preset: which item id sits in each slot (keyed by raw value
/// for stable Codable encoding).
struct GearPreset: Codable, Equatable {
    var equipped: [String: UUID] = [:]

    func itemID(for slot: GearSlot) -> UUID? {
        equipped[slot.rawValue]
    }

    mutating func equip(_ item: GearItem) {
        equipped[item.slot.rawValue] = item.id
    }

    /// Removes the item from whatever slot holds it (starforce destroy).
    mutating func remove(itemID: UUID) {
        equipped = equipped.filter { $0.value != itemID }
    }
}
