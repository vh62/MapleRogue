import Foundation

/// Skill rarity tiers with MapleStory-style weighting.
/// nonisolated: pure domain value type — must be usable off the main actor
/// (e.g. in tests and future background simulation).
nonisolated enum Rarity: Int, CaseIterable, Comparable {
    case common, rare, epic, unique, legendary

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Pull weight out of 100.
    var weight: Double {
        switch self {
        case .common: 60
        case .rare: 25
        case .epic: 10
        case .unique: 4
        case .legendary: 1
        }
    }

    var displayName: String {
        switch self {
        case .common: "Common"
        case .rare: "Rare"
        case .epic: "Epic"
        case .unique: "Unique"
        case .legendary: "Legendary"
        }
    }
}

/// What a pulled skill does to the hero. One effect per skill.
enum SkillEffect: Equatable {
    case attackPercent(Int)
    case attackSpeedPercent(Int)
    case moveSpeedPercent(Int)
    case maxHP(Int)
    case multishot(Int)         // extra projectiles per attack
    case pierce(Int)            // enemies a projectile passes through
    case critRatePercent(Int)   // added crit chance (percentage points)
}

struct SkillDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let rarity: Rarity
    let effect: SkillEffect
}

/// Injectable randomness so gacha odds are unit-testable.
protocol RandomSource {
    /// Uniform value in [0, 1).
    mutating func nextUniform() -> Double
}

struct SystemRandomSource: RandomSource {
    mutating func nextUniform() -> Double { .random(in: 0..<1) }
}

/// The gacha machine: weighted rarity roll with a pity counter that
/// guarantees Epic-or-better every `pityThreshold` pulls.
final class GachaMachine {

    let pityThreshold: Int
    private(set) var pullsSincePity = 0
    private var random: RandomSource

    init(pityThreshold: Int = 10, random: RandomSource = SystemRandomSource()) {
        self.pityThreshold = pityThreshold
        self.random = random
    }

    var pullsUntilPity: Int { pityThreshold - pullsSincePity }

    func pull(from pool: [SkillDefinition]) -> SkillDefinition {
        precondition(!pool.isEmpty, "Gacha pool must not be empty")

        pullsSincePity += 1
        let pityTriggered = pullsSincePity >= pityThreshold

        let rarity = pityTriggered ? rollRarity(minimum: .epic) : rollRarity(minimum: .common)
        if rarity >= .epic {
            pullsSincePity = 0
        }

        // Prefer exact rarity; fall back to nearest lower tier with skills.
        let candidates = candidatePool(pool, rarity: rarity)
        let index = Int(random.nextUniform() * Double(candidates.count))
        return candidates[Swift.min(index, candidates.count - 1)]
    }

    private func rollRarity(minimum: Rarity) -> Rarity {
        let tiers = Rarity.allCases.filter { $0 >= minimum }
        let totalWeight = tiers.map(\.weight).reduce(0, +)
        var roll = random.nextUniform() * totalWeight

        for tier in tiers {
            roll -= tier.weight
            if roll < 0 { return tier }
        }
        return tiers.last ?? .common
    }

    private func candidatePool(_ pool: [SkillDefinition], rarity: Rarity) -> [SkillDefinition] {
        var tier = rarity
        while true {
            let matches = pool.filter { $0.rarity == tier }
            if !matches.isEmpty { return matches }
            guard let lower = Rarity(rawValue: tier.rawValue - 1) else { return pool }
            tier = lower
        }
    }
}
