import Foundation

/// Pure domain model for run currency (Mesos). No SpriteKit.
struct Wallet {
    private(set) var gold: Int = 0

    mutating func add(_ amount: Int) {
        gold += Swift.max(0, amount)
    }

    /// Returns true and deducts if affordable; false leaves the wallet untouched.
    mutating func spend(_ amount: Int) -> Bool {
        guard amount >= 0, gold >= amount else { return false }
        gold -= amount
        return true
    }
}
