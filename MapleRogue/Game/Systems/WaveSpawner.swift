import SpriteKit

/// Declares what spawns in each room and where. Difficulty scales with room number.
final class WaveSpawner {

    private let roomRect: CGRect

    init(roomRect: CGRect) {
        self.roomRect = roomRect
    }

    /// Wave composition per room. Slimes only early; mushrooms from room 2,
    /// boogies from room 3, mixes ramping up from there.
    private func waveComposition(forRoom room: Int) -> [() -> EnemyNode] {
        let slimes = Swift.max(3, 4 + room - (room / 2))
        let mushrooms = room >= 2 ? 1 + (room - 2) / 2 : 0
        let boogies = room >= 3 ? 1 + (room - 3) / 2 : 0

        return Array(repeating: EnemyFactory.slime, count: slimes)
             + Array(repeating: EnemyFactory.mushroom, count: mushrooms)
             + Array(repeating: EnemyFactory.boogie, count: boogies)
    }

    /// Spawns the wave for `room` into the scene and returns the enemies.
    func spawnWave(forRoom room: Int,
                   in scene: SKScene,
                   avoiding heroPosition: CGPoint,
                   onDeath: @escaping (EnemyNode) -> Void) -> [EnemyNode] {
        var spawned: [EnemyNode] = []

        for makeEnemy in waveComposition(forRoom: room) {
            let enemy = makeEnemy()
            enemy.position = randomSpawnPoint(awayFrom: heroPosition)
            enemy.onDeath = onDeath
            scene.addChild(enemy)
            spawned.append(enemy)
        }
        return spawned
    }

    /// Random point inside the room, at least `minDistance` from the hero
    /// so enemies never spawn on top of the player.
    private func randomSpawnPoint(awayFrom heroPosition: CGPoint,
                                  minDistance: CGFloat = 250) -> CGPoint {
        let inset = roomRect.insetBy(dx: 60, dy: 60)
        for _ in 0..<20 {
            let point = CGPoint(x: .random(in: inset.minX...inset.maxX),
                                y: .random(in: inset.minY...inset.maxY))
            if hypot(point.x - heroPosition.x, point.y - heroPosition.y) >= minDistance {
                return point
            }
        }
        // Fallback: far corner from the hero.
        return CGPoint(x: heroPosition.x > 0 ? inset.minX : inset.maxX,
                       y: heroPosition.y > 0 ? inset.minY : inset.maxY)
    }
}
