import Testing
@testable import MapleRogue

/// Deterministic RNG for testing probability-dependent systems.
/// Returns the queued values in order, cycling if exhausted.
struct FixedRandomSource: RandomSource {
    let values: [Double]
    private var index = 0

    init(_ values: [Double]) {
        self.values = values
    }

    mutating func nextUniform() -> Double {
        defer { index += 1 }
        return values[index % values.count]
    }
}

struct DamageRollerTests {

    @Test func rollBelowCritChanceCrits() {
        var roller = DamageRoller(critChance: 0.2, critMultiplier: 1.5,
                                  random: FixedRandomSource([0.1]))
        let roll = roller.roll(base: 100)
        #expect(roll.isCrit)
        #expect(roll.amount == 150)
    }

    @Test func rollAboveCritChanceDoesNotCrit() {
        var roller = DamageRoller(critChance: 0.2, critMultiplier: 1.5,
                                  random: FixedRandomSource([0.5]))
        let roll = roller.roll(base: 100)
        #expect(!roll.isCrit)
        #expect(roll.amount == 100)
    }

    @Test func zeroCritChanceNeverCrits() {
        var roller = DamageRoller(critChance: 0, critMultiplier: 2,
                                  random: FixedRandomSource([0.0, 0.5, 0.999]))
        for _ in 0..<3 {
            #expect(!roller.roll(base: 10).isCrit)
        }
    }

    /// Distribution check: with real RNG, observed crit rate over many rolls
    /// should approximate the configured chance (the plan's "test the weighted
    /// RNG, not manual spot checks" criterion).
    @Test func critDistributionApproximatesConfiguredChance() {
        var roller = DamageRoller(critChance: 0.25, critMultiplier: 1.5)
        let trials = 20_000
        var crits = 0
        for _ in 0..<trials where roller.roll(base: 10).isCrit {
            crits += 1
        }
        let observed = Double(crits) / Double(trials)
        #expect(abs(observed - 0.25) < 0.02, "observed crit rate \(observed) not within 2% of 0.25")
    }
}

struct LoadoutCritTests {

    @Test func critSkillsAggregate() {
        var loadout = HeroLoadout()
        loadout.add(.init(id: "a", name: "A", blurb: "", rarity: .epic,
                          effect: .critRatePercent(15)))
        loadout.add(.init(id: "b", name: "B", blurb: "", rarity: .epic,
                          effect: .critRatePercent(10)))
        loadout.add(.init(id: "c", name: "C", blurb: "", rarity: .common,
                          effect: .attackPercent(20)))   // must not count
        #expect(loadout.critRatePercent == 25)
    }
}

struct LevelCurveTests {

    @Test func firstLevelNeeds100XP() {
        #expect(LevelCurve.xpToNext(from: 1) == 100)
    }

    @Test func applyCarriesOverflowAcrossLevels() {
        // 100 (1→2) + 282 (2→3) = 382; 400 XP leaves 18 into level 3.
        let result = LevelCurve.apply(xp: 400, toLevel: 1, xp: 0)
        #expect(result.level == 3)
        #expect(result.levelsGained == 2)
        #expect(result.xp == 400 - 100 - LevelCurve.xpToNext(from: 2))
    }

    @Test func noLevelUpBelowThreshold() {
        let result = LevelCurve.apply(xp: 99, toLevel: 1, xp: 0)
        #expect(result.level == 1)
        #expect(result.levelsGained == 0)
        #expect(result.xp == 99)
    }

    @Test func gearRequirementRespectsRarityBump() {
        let common = GearItem(slot: .ring, rarity: .common, level: 3)
        let legendary = GearItem(slot: .ring, rarity: .legendary, level: 3)
        #expect(common.requiredLevel == 1)
        #expect(legendary.requiredLevel == 6)
    }
}

struct StarforceTests {

    @Test func successAddsStar() {
        var item = GearItem(slot: .weapon, rarity: .common, level: 1)
        var system = StarforceSystem(random: FixedRandomSource([0.0]))
        let outcome = system.attempt(on: &item)
        #expect(outcome == .success(newStars: 1))
        #expect(item.stars == 1)
    }

    @Test func destroyRollInDestroyBand() {
        // At 15+ stars: success 25%, destroy 10%. Roll 0.30 → 30/100 lands
        // past success (25) but inside success+destroy (35): destroyed.
        var item = GearItem(slot: .weapon, rarity: .common, level: 1, stars: 15)
        var system = StarforceSystem(random: FixedRandomSource([0.30]))
        #expect(system.attempt(on: &item) == .destroyed)
    }

    @Test func failLeavesItemUntouched() {
        // Roll 0.50 at 15 stars → past success+destroy (35): plain fail.
        var item = GearItem(slot: .weapon, rarity: .common, level: 1, stars: 15)
        var system = StarforceSystem(random: FixedRandomSource([0.50]))
        #expect(system.attempt(on: &item) == .fail)
        #expect(item.stars == 15)
    }

    @Test func maxStarsReturnsNil() {
        var item = GearItem(slot: .weapon, rarity: .common, level: 1, stars: GearItem.maxStars)
        var system = StarforceSystem(random: FixedRandomSource([0.0]))
        #expect(system.attempt(on: &item) == nil)
    }

    @Test func starsFeedAtkPercent() {
        let item = GearItem(slot: .weapon, rarity: .common, level: 4, stars: 3)
        // level 4 common: 4*1/2 = 2%, stars: 3*8 = 24%.
        #expect(item.atkPercent == 26)
    }
}

struct RunLevelingTests {

    @Test func curveValues() {
        var leveling = RunLeveling()
        #expect(leveling.xpToNext == 25)   // 15 + 10×1
        _ = leveling.gain(25)
        #expect(leveling.level == 2)
        #expect(leveling.xpToNext == 35)   // 15 + 10×2
    }

    @Test func burstGainCrossesMultipleLevels() {
        var leveling = RunLeveling()
        // 25 (1→2) + 35 (2→3) = 60; 70 XP leaves 10 into level 3.
        let ups = leveling.gain(70)
        #expect(ups == 2)
        #expect(leveling.level == 3)
        #expect(leveling.xpIntoLevel == 10)
    }

    @Test func belowThresholdNoLevelUp() {
        var leveling = RunLeveling()
        #expect(leveling.gain(24) == 0)
        #expect(leveling.level == 1)
        #expect(leveling.xpIntoLevel == 24)
    }
}

struct SkillChooserTests {

    @Test func offersThreeDistinctSkills() {
        var chooser = SkillChooser()
        for _ in 0..<50 {
            let offer = chooser.offer(from: SkillRegistry.all)
            #expect(offer.count == 3)
            #expect(Set(offer.map(\.id)).count == 3, "duplicate skill in one offer")
        }
    }

    @Test func lowRollsOfferCommons() {
        // All-zero rolls: every rarity roll lands common, picks first candidate.
        var chooser = SkillChooser(random: FixedRandomSource([0.0]))
        let offer = chooser.offer(from: SkillRegistry.all)
        #expect(offer.allSatisfy { $0.rarity == .common })
    }

    @Test func rarityDistributionRoughlyMatchesWeights() {
        var chooser = SkillChooser()
        var legendaries = 0
        let trials = 3000
        for _ in 0..<trials {
            legendaries += chooser.offer(from: SkillRegistry.all)
                .filter { $0.rarity == .legendary }.count
        }
        // ~1% per card × 3 cards × 3000 ≈ 90; allow generous slack for
        // the distinctness re-roll skew.
        let perCardRate = Double(legendaries) / Double(trials * 3)
        #expect(perCardRate > 0.002 && perCardRate < 0.03,
                "legendary rate \(perCardRate) far from ~1%")
    }
}
