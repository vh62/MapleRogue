import Foundation

/// Combat-wide tuning constants — one source of truth.
enum CombatTuning {
    static let baseCritChance = 0.05
    static let baseCritMultiplier = 1.5
}

/// Everything meta-progression contributes to a run, aggregated from
/// equipped gear (levels, stars, cube potentials). Class stats are the
/// base; this stacks on top.
struct HeroBuild {
    var atkPercent = 0
    var bonusHP = 0
    var critRatePercent = 0
    var critDmgPercent = 0
    var moveSpeedPercent = 0
}

/// Result of one damage computation.
struct DamageRoll: Equatable {
    let amount: Int
    let isCrit: Bool
}

/// Pure damage math with crit — injectable RNG so distributions are testable.
/// Cube potential lines (Phase 1) will feed critChance/critMultiplier.
struct DamageRoller {

    /// 0.0–1.0 chance that a hit crits.
    var critChance: Double
    /// Damage multiplier on crit (1.5 = +50%).
    var critMultiplier: Double
    var random: RandomSource

    init(critChance: Double = CombatTuning.baseCritChance,
         critMultiplier: Double = CombatTuning.baseCritMultiplier,
         random: RandomSource = SystemRandomSource()) {
        self.critChance = critChance
        self.critMultiplier = critMultiplier
        self.random = random
    }

    mutating func roll(base: Int) -> DamageRoll {
        let isCrit = random.nextUniform() < critChance
        let amount = isCrit ? Int(Double(base) * critMultiplier) : base
        return DamageRoll(amount: amount, isCrit: isCrit)
    }
}
