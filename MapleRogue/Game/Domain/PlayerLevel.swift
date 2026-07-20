import Foundation

/// Account-level XP curve. Pure domain, testable.
enum LevelCurve {

    /// XP required to go from `level` to `level + 1`.
    static func xpToNext(from level: Int) -> Int {
        Int(100 * pow(Double(max(1, level)), 1.5))
    }

    /// Applies earned XP to (level, xp) and returns the updated pair
    /// plus how many levels were gained.
    static func apply(xp earned: Int, toLevel level: Int, xp: Int)
        -> (level: Int, xp: Int, levelsGained: Int) {
        var level = max(1, level)
        var xp = max(0, xp) + max(0, earned)
        var gained = 0

        while xp >= xpToNext(from: level) {
            xp -= xpToNext(from: level)
            level += 1
            gained += 1
        }
        return (level, xp, gained)
    }
}

/// XP values for run events.
enum XPReward {
    static let roomCleared = 25
    static let runCompleted = 100
}

/// Run-scoped leveling (Archero-style): kills fill the bar, each level-up
/// grants a skill choice. Resets every run — unrelated to account level.
struct RunLeveling {
    private(set) var level: Int = 1
    private(set) var xpIntoLevel: Int = 0

    /// XP needed to go from `level` to `level + 1`.
    var xpToNext: Int { 15 + 10 * level }

    var fraction: Double { Double(xpIntoLevel) / Double(xpToNext) }

    /// Feeds XP in; returns how many level-ups this gain produced.
    mutating func gain(_ xp: Int) -> Int {
        xpIntoLevel += Swift.max(0, xp)
        var levelUps = 0
        while xpIntoLevel >= xpToNext {
            xpIntoLevel -= xpToNext
            level += 1
            levelUps += 1
        }
        return levelUps
    }
}
