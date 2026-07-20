import Testing
@testable import MapleRogue

struct CubeTests {

    private func makeItem(rank: GearRarity = .common) -> GearItem {
        GearItem(slot: .weapon, rarity: rank, level: 1)
    }

    @Test func lineCountMatchesRank() {
        #expect(PotentialPool.lineCount(for: .common) == 1)
        #expect(PotentialPool.lineCount(for: .rare) == 2)
        #expect(PotentialPool.lineCount(for: .epic) == 3)
        #expect(PotentialPool.lineCount(for: .legendary) == 3)
    }

    @Test func rollProducesLinesAtItemRank() {
        var item = makeItem(rank: .rare)
        var system = CubeSystem(random: FixedRandomSource([0.99]))   // never rank up
        let result = system.use(.basic, on: &item)
        #expect(result.lines.count == PotentialPool.lineCount(for: .rare))
        #expect(item.potentialLines == result.lines)
    }

    @Test func lowRankUpRollRanksUp() {
        var item = makeItem(rank: .common)
        // First value: rank-up roll (0.01 < 0.05 succeeds). Rest: line rolls.
        var system = CubeSystem(random: FixedRandomSource([0.01, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]))
        let result = system.use(.basic, on: &item)
        #expect(result.rankedUp)
        #expect(item.rarity == .rare)
        #expect(item.cubePity == 0)   // reset on rank-up
    }

    @Test func cubeRespectsMaxRank() {
        var item = makeItem(rank: .epic)   // basic cube caps at epic
        var system = CubeSystem(random: FixedRandomSource([0.0]))
        let result = system.use(.basic, on: &item)
        #expect(!result.rankedUp)
        #expect(item.rarity == .epic)
    }

    @Test func primeLineRollsBoostedValue() {
        // Rolls: rank-up (fail 0.99), stat pick (0.0 → first stat, pctATK),
        // prime roll (0.0 < 0.10 → prime), value roll (0.0 → range min).
        var item = makeItem(rank: .common)
        var system = CubeSystem(random: FixedRandomSource([0.99, 0.0, 0.0, 0.0]))
        let result = system.use(.basic, on: &item)
        let line = result.lines[0]
        #expect(line.isPrime)
        let baseMin = PotentialPool.valueRange(for: line.stat, rank: .common).lowerBound
        #expect(line.value == Int(Double(baseMin) * 1.5))
    }

    // MARK: - Premium (keep-or-replace)

    @Test func premiumRollWithoutRankUpLeavesLinesPending() {
        let oldLines = [PotentialLine(stat: .pctATK, value: 5, isPrime: false)]
        var item = GearItem(slot: .weapon, rarity: .legendary, level: 1,
                            potentialLines: oldLines)
        var system = CubeSystem(random: FixedRandomSource([0.5]))
        let roll = system.roll(.premium, on: &item)
        #expect(!roll.autoApplied)
        #expect(item.potentialLines == oldLines)   // untouched until confirmed
        #expect(roll.newLines.count == PotentialPool.lineCount(for: .legendary))
    }

    @Test func premiumRankUpAutoAppliesNewLines() {
        let oldLines = [PotentialLine(stat: .pctATK, value: 5, isPrime: false)]
        var item = GearItem(slot: .weapon, rarity: .epic, level: 1,
                            potentialLines: oldLines)
        // 0.01 < 0.12 rank-up chance → ranks to legendary, lines must reroll.
        var system = CubeSystem(random: FixedRandomSource([0.01, 0.5]))
        let roll = system.roll(.premium, on: &item)
        #expect(roll.rankedUp)
        #expect(roll.autoApplied)
        #expect(item.rarity == .legendary)
        #expect(item.potentialLines == roll.newLines)
    }

    @Test func premiumEmptyItemAutoApplies() {
        var item = makeItem(rank: .legendary)   // no lines yet
        var system = CubeSystem(random: FixedRandomSource([0.5]))
        let roll = system.roll(.premium, on: &item)
        #expect(roll.autoApplied)
        #expect(item.potentialLines == roll.newLines)
    }

    /// The plan's Phase 4 acceptance criterion: simulate many cube
    /// sequences and confirm no streak of failed rank-ups ever exceeds
    /// the pity threshold.
    @Test func pityNeverExceedsThresholdOver1000Sequences() {
        var system = CubeSystem()   // real RNG
        var worstStreak = 0

        for _ in 0..<1000 {
            var item = makeItem(rank: .common)
            var streak = 0
            // Push one item from common toward epic.
            for _ in 0..<60 {
                let before = item.rarity
                _ = system.use(.basic, on: &item)
                if item.rarity == before && before < CubeType.basic.maxRank {
                    streak += 1
                    worstStreak = max(worstStreak, streak)
                } else {
                    streak = 0
                }
                if item.rarity == .epic { break }
            }
        }

        #expect(worstStreak < CubeType.basic.pityThreshold,
                "worst failed streak \(worstStreak) reached pity threshold \(CubeType.basic.pityThreshold)")
    }
}
