import SpriteKit

/// Declares what spawns in each room and where. Difficulty scales with room number.
final class WaveSpawner {

    private let roomRect: CGRect

    init(roomRect: CGRect) {
        self.roomRect = roomRect
    }

    /// Chance any spawned enemy is an elite (3× HP, 4× gold, bonus token).
    var eliteChance = 0.08

    private enum WaveTheme: CaseIterable {
        case standard   // balanced mix
        case horde      // many weak slimes
        case snipers    // boogie-heavy, mushroom bodyguards
    }

    /// Wave composition per room. Early rooms are always standard; from
    /// room 3 a random theme keeps runs from blurring together.
    private func waveComposition(forRoom room: Int) -> [(Bool) -> EnemyNode] {
        let theme: WaveTheme = room >= 3 ? (WaveTheme.allCases.randomElement() ?? .standard) : .standard

        let slimes: Int
        let mushrooms: Int
        let boogies: Int

        switch theme {
        case .standard:
            slimes = Swift.max(3, 4 + room - (room / 2))
            mushrooms = room >= 2 ? 1 + (room - 2) / 2 : 0
            boogies = room >= 3 ? 1 + (room - 3) / 2 : 0
        case .horde:
            slimes = 8 + room
            mushrooms = 0
            boogies = 0
        case .snipers:
            slimes = 0
            mushrooms = 2
            boogies = 3 + room / 2
        }

        return Array(repeating: EnemyFactory.slime(elite:), count: slimes)
             + Array(repeating: EnemyFactory.mushroom(elite:), count: mushrooms)
             + Array(repeating: EnemyFactory.boogie(elite:), count: boogies)
    }

    /// Spawns the wave for `room` into the scene and returns the enemies.
    func spawnWave(forRoom room: Int,
                   in scene: SKScene,
                   avoiding heroPosition: CGPoint,
                   onDeath: @escaping (EnemyNode) -> Void) -> [EnemyNode] {
        var spawned: [EnemyNode] = []

        for makeEnemy in waveComposition(forRoom: room) {
            let enemy = makeEnemy(Double.random(in: 0..<1) < eliteChance)
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
