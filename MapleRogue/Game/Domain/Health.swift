import Foundation

/// Pure domain model for hit points. No SpriteKit — unit-testable.
struct Health {
    private(set) var max: Int
    private(set) var current: Int

    init(max: Int) {
        self.max = max
        self.current = max
    }

    var isDead: Bool { current <= 0 }
    var fraction: Double { Double(current) / Double(max) }

    /// Applies damage and returns the amount actually dealt.
    @discardableResult
    mutating func takeDamage(_ amount: Int) -> Int {
        let dealt = min(current, Swift.max(0, amount))
        current -= dealt
        return dealt
    }

    mutating func heal(_ amount: Int) {
        current = Swift.min(max, current + Swift.max(0, amount))
    }

    /// Raises the cap and heals by the same amount (skill pickups feel good).
    mutating func increaseMax(by amount: Int) {
        max += Swift.max(0, amount)
        current += Swift.max(0, amount)
    }
}

/// Anything that can receive damage from combat.
protocol Damageable: AnyObject {
    var health: Health { get }
    func applyDamage(_ amount: Int)
}
