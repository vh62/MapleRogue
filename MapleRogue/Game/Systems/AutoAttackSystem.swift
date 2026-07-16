import SpriteKit

/// Finds the nearest visible enemy and fires pooled projectiles on a cooldown.
/// Owns targeting rules; knows nothing about rooms, waves, or UI.
final class AutoAttackSystem {

    // Tunables — the scene overwrites these from the hero's loadout.
    var attackInterval: TimeInterval = 0.5
    var projectileSpeed: CGFloat = 550
    var damage: Int = 12
    var range: CGFloat = 450
    var extraProjectiles: Int = 0
    var pierceCount: Int = 0
    /// Crit math lives in the domain; the system just rolls per projectile.
    var damageRoller = DamageRoller()

    private let pool: ProjectilePool
    private var timeUntilNextShot: TimeInterval = 0

    init(pool: ProjectilePool) {
        self.pool = pool
    }

    func update(deltaTime: TimeInterval,
                heroPosition: CGPoint,
                heroIsMoving: Bool,
                enemies: [EnemyNode],
                scene: SKScene) {
        timeUntilNextShot -= deltaTime

        // Archero rule: moving means dodging, standing still means shooting.
        // The whole risk/reward loop hangs on this gate.
        guard !heroIsMoving else { return }
        guard timeUntilNextShot <= 0 else { return }

        guard let target = nearestVisibleEnemy(from: heroPosition,
                                               enemies: enemies,
                                               in: scene) else { return }

        timeUntilNextShot = attackInterval
        SoundSystem.shared.play(.shoot, in: scene)

        let baseAngle = atan2(target.position.y - heroPosition.y,
                              target.position.x - heroPosition.x)

        // 1 main shot + extras fanned out at ±12° steps.
        let spread: CGFloat = .pi / 15
        let count = 1 + extraProjectiles
        for index in 0..<count {
            let offset = CGFloat(index) - CGFloat(count - 1) / 2
            let angle = baseAngle + offset * spread
            let roll = damageRoller.roll(base: damage)
            pool.spawn(in: scene).fire(from: heroPosition,
                                       direction: CGVector(dx: cos(angle), dy: sin(angle)),
                                       speed: projectileSpeed,
                                       damage: roll.amount,
                                       pierce: pierceCount,
                                       isCrit: roll.isCrit)
        }
    }

    private func nearestVisibleEnemy(from origin: CGPoint,
                                     enemies: [EnemyNode],
                                     in scene: SKScene) -> EnemyNode? {
        enemies
            .filter { !$0.health.isDead }
            .map { (enemy: $0, distance: hypot($0.position.x - origin.x,
                                               $0.position.y - origin.y)) }
            .filter { $0.distance <= range }
            .sorted { $0.distance < $1.distance }
            .first { hasLineOfSight(from: origin, to: $0.enemy.position, in: scene) }?
            .enemy
    }

    private func hasLineOfSight(from origin: CGPoint,
                                to target: CGPoint,
                                in scene: SKScene) -> Bool {
        var blocked = false
        scene.physicsWorld.enumerateBodies(alongRayStart: origin, end: target) { body, _, _, stop in
            if body.categoryBitMask == PhysicsCategory.wall {
                blocked = true
                stop.pointee = true
            }
        }
        return !blocked
    }
}
