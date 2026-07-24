import SpriteKit

/// Owns the gold-orb lifecycle: dropping from dead enemies, magnet pull,
/// collection. The scene only forwards frame updates and banks the totals.
final class GoldOrbSystem {

    // Tunables
    var magnetRadius: CGFloat = 240
    var collectRadius: CGFloat = 60
    var pullSpeed: CGFloat = 520

    private var orbs: [GoldOrbNode] = []

    /// Splits the enemy's value into 1–3 orbs for a satisfying scatter.
    func drop(from enemy: EnemyNode, in scene: SKScene) {
        let orbCount = Int.random(in: 1...3)
        let valuePerOrb = max(1, enemy.goldValue / orbCount)
        for _ in 0..<orbCount {
            let orb = GoldOrbNode(value: valuePerOrb)
            orb.scatter(from: enemy.position)
            orbs.append(orb)
            scene.addChild(orb)
        }
    }

    /// Pulls nearby orbs toward the hero; returns gold collected this frame.
    func update(deltaTime: TimeInterval, heroPosition: CGPoint) -> Int {
        var collectedValue = 0
        var remaining: [GoldOrbNode] = []
        remaining.reserveCapacity(orbs.count)

        for orb in orbs {
            let dx = heroPosition.x - orb.position.x
            let dy = heroPosition.y - orb.position.y
            let distance = hypot(dx, dy)

            if distance < collectRadius {
                collectedValue += orb.value
                orb.removeFromParent()
            } else {
                if distance < magnetRadius {
                    let step = pullSpeed * CGFloat(deltaTime)
                    orb.position.x += dx / distance * step
                    orb.position.y += dy / distance * step
                }
                remaining.append(orb)
            }
        }

        orbs = remaining
        return collectedValue
    }

    /// Collects everything left on the floor (room exit) and returns its value.
    func collectRemaining() -> Int {
        let total = orbs.reduce(0) { $0 + $1.value }
        orbs.forEach { $0.removeFromParent() }
        orbs.removeAll()
        return total
    }
}
