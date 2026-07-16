import Foundation

/// MapleStory-style enhancement odds. All percentages out of 100;
/// whatever success + destroy don't cover is a plain fail (nothing happens).
enum StarforceTable {

    struct Odds {
        let success: Double
        let destroy: Double
        var fail: Double { 100 - success - destroy }
    }

    static func odds(forStar current: Int) -> Odds {
        switch current {
        case 0..<5:   Odds(success: 95 - Double(current) * 5, destroy: 0)
        case 5..<10:  Odds(success: 65 - Double(current - 5) * 5, destroy: 0)
        case 10..<15: Odds(success: 40 - Double(current - 10) * 2.5, destroy: 3 + Double(current - 10))
        default:      Odds(success: 25, destroy: 10)
        }
    }

    /// Meso cost rises with star level.
    static func cost(forStar current: Int) -> Int {
        50 + current * 35
    }
}

enum StarforceOutcome: Equatable {
    case success(newStars: Int)
    case fail
    case destroyed
}

/// Rolls one enhancement attempt on a gear item. Injectable RNG —
/// same pattern as the gacha and chests.
struct StarforceSystem {

    var random: RandomSource = SystemRandomSource()

    /// Mutates the item on success. Returns nil if already at max stars.
    /// On `.destroyed` the caller is responsible for removing the item.
    mutating func attempt(on item: inout GearItem) -> StarforceOutcome? {
        guard item.stars < GearItem.maxStars else { return nil }

        let odds = StarforceTable.odds(forStar: item.stars)
        let roll = random.nextUniform() * 100

        if roll < odds.success {
            item.addStar()
            return .success(newStars: item.stars)
        } else if roll < odds.success + odds.destroy {
            return .destroyed
        } else {
            return .fail
        }
    }
}
