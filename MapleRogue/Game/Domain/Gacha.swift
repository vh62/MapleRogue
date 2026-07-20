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

/// Rolls the per-room skill offer: 3 distinct skills, each card's rarity
/// drawn independently from the weighted table (Archero pick-1-of-3).
/// No pity here — the gambling layer lives in equipment (cubes/starforce).
struct SkillChooser {

    var random: RandomSource = SystemRandomSource()

    mutating func offer(from pool: [SkillDefinition], count: Int = 3) -> [SkillDefinition] {
        precondition(!pool.isEmpty, "Skill pool must not be empty")
        var offered: [SkillDefinition] = []
        var attempts = 0

        while offered.count < min(count, pool.count) && attempts < 40 {
            attempts += 1
            let rarity = rollRarity()
            let candidates = pool.filter { skill in
                skill.rarity == rarity && !offered.contains(where: { $0.id == skill.id })
            }
            guard !candidates.isEmpty else { continue }
            let index = min(Int(random.nextUniform() * Double(candidates.count)),
                            candidates.count - 1)
            offered.append(candidates[index])
        }

        // Fallback: pad with any distinct skills if rarity rolls kept missing.
        if offered.count < min(count, pool.count) {
            for skill in pool.shuffled() where !offered.contains(where: { $0.id == skill.id }) {
                offered.append(skill)
                if offered.count == min(count, pool.count) { break }
            }
        }
        return offered
    }

    private mutating func rollRarity() -> Rarity {
        let totalWeight = Rarity.allCases.map(\.weight).reduce(0, +)
        var roll = random.nextUniform() * totalWeight
        for tier in Rarity.allCases {
            roll -= tier.weight
            if roll < 0 { return tier }
        }
        return .common
    }
}
