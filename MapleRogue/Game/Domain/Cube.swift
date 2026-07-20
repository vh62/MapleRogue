import Foundation

/// Stats a potential line can roll. Every case maps to a value the combat
/// engine actually reads — no dead stats.
enum PotentialStat: String, Codable, CaseIterable {
    case pctATK
    case flatHP
    case critRate
    case critDmg
    case moveSpeed

    var displayName: String {
        switch self {
        case .pctATK: "ATK"
        case .flatHP: "Max HP"
        case .critRate: "Crit Rate"
        case .critDmg: "Crit Damage"
        case .moveSpeed: "Move Speed"
        }
    }

    func format(_ value: Int) -> String {
        switch self {
        case .flatHP: "+\(value) \(displayName)"
        default: "+\(value)% \(displayName)"
        }
    }
}

/// One rolled stat line on an item.
struct PotentialLine: Codable, Equatable, Identifiable {
    let id: UUID
    let stat: PotentialStat
    let value: Int
    /// Prime lines roll 1.5× value — the jackpot within the jackpot.
    let isPrime: Bool

    init(id: UUID = UUID(), stat: PotentialStat, value: Int, isPrime: Bool) {
        self.id = id
        self.stat = stat
        self.value = value
        self.isPrime = isPrime
    }
}

/// Value tuning per stat and rank. Balance lives here and nowhere else.
enum PotentialPool {

    /// Lines rolled per rank: commons get 1, legendaries get 3.
    static func lineCount(for rank: GearRarity) -> Int {
        switch rank {
        case .common: 1
        case .rare: 2
        case .epic, .legendary: 3
        }
    }

    static func valueRange(for stat: PotentialStat, rank: GearRarity) -> ClosedRange<Int> {
        let tier = rankMultiplier(rank)
        switch stat {
        case .pctATK: return (2 * tier)...(5 * tier)
        case .flatHP: return (8 * tier)...(20 * tier)
        case .critRate: return (1 * tier)...(3 * tier)
        case .critDmg: return (3 * tier)...(8 * tier)
        case .moveSpeed: return (1 * tier)...(3 * tier)
        }
    }

    static let primeChance = 0.10

    private static func rankMultiplier(_ rank: GearRarity) -> Int {
        switch rank {
        case .common: 1
        case .rare: 2
        case .epic: 3
        case .legendary: 5
        }
    }
}

/// A cube definition: what it costs, how high it can rank an item, and
/// its rank-up odds. Pity guarantees a rank-up within `pityThreshold` uses.
struct CubeType: Identifiable {
    let id: String
    let name: String
    let maxRank: GearRarity
    let rankUpChance: Double        // 0–1
    let costMesos: Int
    let costGems: Int
    let pityThreshold: Int

    /// Phase 2 cube: meso-priced, capped at Epic. Reroll replaces lines
    /// outright (MapleStory Red Cube behavior).
    static let basic = CubeType(id: "basic", name: "Basic Cube",
                                maxRank: .epic, rankUpChance: 0.05,
                                costMesos: 150, costGems: 0,
                                pityThreshold: 15)

    /// Phase 3 cube: gem-priced, reaches Legendary, better odds — and the
    /// player chooses old vs new lines (MapleStory Black Cube behavior).
    static let premium = CubeType(id: "premium", name: "Premium Cube",
                                  maxRank: .legendary, rankUpChance: 0.12,
                                  costMesos: 0, costGems: 25,
                                  pityThreshold: 10)

    #if DEBUG
    /// Phase 1 tuning cube: free, generous, internal builds only.
    static let debug = CubeType(id: "debug", name: "Debug Cube",
                                maxRank: .legendary, rankUpChance: 0.5,
                                costMesos: 0, costGems: 0,
                                pityThreshold: 3)
    #endif
}

/// Rolls cube results. Injectable RNG — unit-tested against the odds tables.
struct CubeSystem {

    struct Result: Equatable {
        let lines: [PotentialLine]
        let rankedUp: Bool
        let newRank: GearRarity
    }

    var random: RandomSource = SystemRandomSource()

    /// A premium roll awaiting the player's keep-or-replace decision.
    struct PendingRoll: Equatable {
        let newLines: [PotentialLine]
        let rankedUp: Bool
        let newRank: GearRarity
        /// True when the lines were applied immediately (rank-up forces a
        /// reroll at the new rank, and empty items have nothing to keep).
        let autoApplied: Bool
    }

    /// One cube use: possibly ranks the item up (with pity), then rerolls
    /// its full set of potential lines at the (possibly new) rank.
    mutating func use(_ cube: CubeType, on item: inout GearItem) -> Result {
        let rankedUp = rollRankUp(cube, on: &item)
        let lines = rollLines(rank: item.rarity)
        item.setPotential(lines)
        return Result(lines: lines, rankedUp: rankedUp, newRank: item.rarity)
    }

    /// Premium (Black Cube) use: rank-up commits immediately, but new lines
    /// only *replace* the old ones if the caller confirms — unless the
    /// rank changed or the item had no lines, in which case they auto-apply.
    mutating func roll(_ cube: CubeType, on item: inout GearItem) -> PendingRoll {
        let rankedUp = rollRankUp(cube, on: &item)
        let lines = rollLines(rank: item.rarity)

        let mustApply = rankedUp || item.potentialLines.isEmpty
        if mustApply {
            item.setPotential(lines)
        }
        return PendingRoll(newLines: lines,
                           rankedUp: rankedUp,
                           newRank: item.rarity,
                           autoApplied: mustApply)
    }

    private mutating func rollRankUp(_ cube: CubeType, on item: inout GearItem) -> Bool {
        guard item.rarity < cube.maxRank else { return false }
        item.incrementCubePity()
        if random.nextUniform() < cube.rankUpChance || item.cubePity >= cube.pityThreshold {
            item.rankUp()
            return true
        }
        return false
    }

    private mutating func rollLines(rank: GearRarity) -> [PotentialLine] {
        let count = PotentialPool.lineCount(for: rank)
        return (0..<count).map { index in
            let stats = PotentialStat.allCases
            let stat = stats[min(Int(random.nextUniform() * Double(stats.count)), stats.count - 1)]

            // Only the first line can roll prime.
            let isPrime = index == 0 && random.nextUniform() < PotentialPool.primeChance

            let range = PotentialPool.valueRange(for: stat, rank: rank)
            let span = Double(range.upperBound - range.lowerBound + 1)
            var value = range.lowerBound + min(Int(random.nextUniform() * span), range.upperBound - range.lowerBound)
            if isPrime {
                value = Int(Double(value) * 1.5)
            }
            return PotentialLine(stat: stat, value: value, isPrime: isPrime)
        }
    }
}
