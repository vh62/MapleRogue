import Foundation

/// Gear chests — the shop's functional sink. Odds are disclosed in the UI
/// (App Store guideline 3.1.1).
enum ChestType: String, CaseIterable, Identifiable {
    case basic
    case premium

    var id: String { rawValue }

    var name: String {
        switch self {
        case .basic: "Basic Chest"
        case .premium: "Premium Chest"
        }
    }

    /// (currency, amount)
    var cost: (mesos: Int, gems: Int) {
        switch self {
        case .basic: (mesos: 200, gems: 0)
        case .premium: (mesos: 0, gems: 30)
        }
    }

    /// Rarity weights out of 100.
    var odds: [(rarity: GearRarity, weight: Double)] {
        switch self {
        case .basic:
            [(.common, 70), (.rare, 25), (.epic, 5), (.legendary, 0)]
        case .premium:
            [(.common, 25), (.rare, 45), (.epic, 25), (.legendary, 5)]
        }
    }
}

/// Rolls chest contents. Injectable RNG — same pattern as gacha/starforce.
struct ChestSystem {

    var random: RandomSource = SystemRandomSource()

    mutating func open(_ chest: ChestType) -> GearItem {
        let odds = chest.odds
        let total = odds.map(\.weight).reduce(0, +)
        var roll = random.nextUniform() * total

        var rarity: GearRarity = .common
        for entry in odds {
            roll -= entry.weight
            if roll < 0 {
                rarity = entry.rarity
                break
            }
        }

        let slot = GearSlot.allCases[Int(random.nextUniform() * Double(GearSlot.allCases.count))
                                     % GearSlot.allCases.count]
        let level = 1 + Int(random.nextUniform() * 5)
        return GearItem(slot: slot, rarity: rarity, level: level)
    }
}

/// Gem IAP tiers. `price` is display-only until StoreKit lands.
/// Per strategy: "BEST VALUE" tag goes on the second-largest tier.
struct GemPack: Identifiable {
    let id: String
    let gems: Int
    let priceLabel: String
    let bestValue: Bool

    static let all: [GemPack] = [
        GemPack(id: "gems_s", gems: 100, priceLabel: "$0.99", bestValue: false),
        GemPack(id: "gems_m", gems: 550, priceLabel: "$4.99", bestValue: false),
        GemPack(id: "gems_l", gems: 1200, priceLabel: "$9.99", bestValue: true),
        GemPack(id: "gems_xl", gems: 2600, priceLabel: "$19.99", bestValue: false),
    ]
}
