import Foundation

/// Single visible number for the standing build (MapleStory Combat Power
/// philosophy: multiplicative damage pipeline, excludes in-run skills —
/// but unlike MS, survivability counts at a small weight).
enum PowerRating {

    // Tuning constants — Power must track what actually wins runs.
    static let dpsWeight = 8.0
    static let ehpWeight = 1.5
    static let mobilityDivisor = 400.0

    static func compute(heroClass: HeroClass, build: HeroBuild) -> Int {
        let atk = Double(heroClass.baseDamage) * (1 + Double(build.atkPercent) / 100)
        let attacksPerSecond = 1.0 / heroClass.attackInterval

        let critChance = CombatTuning.baseCritChance + Double(build.critRatePercent) / 100
        let critMultiplier = CombatTuning.baseCritMultiplier + Double(build.critDmgPercent) / 100
        let critFactor = 1 + critChance * (critMultiplier - 1)

        let dps = atk * attacksPerSecond * critFactor
        let ehp = Double(heroClass.maxHP + build.bonusHP)
        let mobility = 1 + Double(build.moveSpeedPercent) / mobilityDivisor

        return Int((dps * dpsWeight + ehp * ehpWeight) * mobility)
    }
}
