import Foundation

/// All pullable skills. Balance lives here and nowhere else.
enum SkillRegistry {

    static let all: [SkillDefinition] = [
        // Common — 60%
        .init(id: "sharpen", name: "Sharpen", blurb: "+10% attack",
              rarity: .common, effect: .attackPercent(10)),
        .init(id: "swift_boots", name: "Swift Boots", blurb: "+10% move speed",
              rarity: .common, effect: .moveSpeedPercent(10)),
        .init(id: "vitality", name: "Vitality", blurb: "+20 max HP",
              rarity: .common, effect: .maxHP(20)),

        // Rare — 25%
        .init(id: "power_strike", name: "Power Strike", blurb: "+20% attack",
              rarity: .rare, effect: .attackPercent(20)),
        .init(id: "rapid_fire", name: "Rapid Fire", blurb: "+15% attack speed",
              rarity: .rare, effect: .attackSpeedPercent(15)),
        .init(id: "tough_skin", name: "Tough Skin", blurb: "+40 max HP",
              rarity: .rare, effect: .maxHP(40)),

        // Epic — 10%
        .init(id: "multishot", name: "Multishot", blurb: "+1 projectile",
              rarity: .epic, effect: .multishot(1)),
        .init(id: "piercing_arrow", name: "Piercing Arrow", blurb: "Shots pierce 1 enemy",
              rarity: .epic, effect: .pierce(1)),
        .init(id: "berserk", name: "Berserk", blurb: "+35% attack",
              rarity: .epic, effect: .attackPercent(35)),
        .init(id: "sharp_eyes", name: "Sharp Eyes", blurb: "+15% crit rate",
              rarity: .epic, effect: .critRatePercent(15)),

        // Unique — 4%
        .init(id: "twin_fangs", name: "Twin Fangs", blurb: "+2 projectiles",
              rarity: .unique, effect: .multishot(2)),
        .init(id: "deep_pierce", name: "Deep Pierce", blurb: "Shots pierce 3 enemies",
              rarity: .unique, effect: .pierce(3)),

        // Legendary — 1%
        .init(id: "storm_of_arrows", name: "Storm of Arrows", blurb: "+3 projectiles",
              rarity: .legendary, effect: .multishot(3)),
        .init(id: "dragon_force", name: "Dragon Force", blurb: "+80% attack",
              rarity: .legendary, effect: .attackPercent(80)),
    ]
}

/// The skills collected during one run and their combined stat effects.
/// Pure domain — the scene reads aggregates and applies them.
struct HeroLoadout {

    private(set) var skills: [SkillDefinition] = []

    mutating func add(_ skill: SkillDefinition) {
        skills.append(skill)
    }

    // MARK: - Aggregates

    func damage(base: Int) -> Int {
        let percent = skills.reduce(0) { sum, skill in
            if case .attackPercent(let value) = skill.effect { return sum + value }
            return sum
        }
        return base + base * percent / 100
    }

    func attackInterval(base: TimeInterval) -> TimeInterval {
        let percent = skills.reduce(0) { sum, skill in
            if case .attackSpeedPercent(let value) = skill.effect { return sum + value }
            return sum
        }
        return base / (1.0 + Double(percent) / 100.0)
    }

    func moveSpeed(base: Double) -> Double {
        let percent = skills.reduce(0) { sum, skill in
            if case .moveSpeedPercent(let value) = skill.effect { return sum + value }
            return sum
        }
        return base * (1.0 + Double(percent) / 100.0)
    }

    var bonusMaxHP: Int {
        skills.reduce(0) { sum, skill in
            if case .maxHP(let value) = skill.effect { return sum + value }
            return sum
        }
    }

    var extraProjectiles: Int {
        skills.reduce(0) { sum, skill in
            if case .multishot(let value) = skill.effect { return sum + value }
            return sum
        }
    }

    var pierceCount: Int {
        skills.reduce(0) { sum, skill in
            if case .pierce(let value) = skill.effect { return sum + value }
            return sum
        }
    }

    /// Added crit chance in percentage points (15 = +0.15).
    var critRatePercent: Int {
        skills.reduce(0) { sum, skill in
            if case .critRatePercent(let value) = skill.effect { return sum + value }
            return sum
        }
    }
}
