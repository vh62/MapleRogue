import SpriteKit

/// Jr. Boogie: skittish ranged attacker. Keeps a preferred distance from
/// the hero — backs off when crowded, creeps closer when too far — and
/// lobs projectiles on a cooldown.
final class BoogieBehavior: EnemyBehavior {

    let preferredDistance: CGFloat = 300
    let distanceTolerance: CGFloat = 60
    let moveSpeed: CGFloat = 52
    let attackInterval: TimeInterval = 2.2
    let projectileSpeed: CGFloat = 185
    let projectileDamage: Int = 8

    private var timeUntilNextShot: TimeInterval = .random(in: 0.5...2.0)

    func update(enemy: EnemyNode, heroPosition: CGPoint, deltaTime: TimeInterval) {
        let dx = heroPosition.x - enemy.position.x
        let dy = heroPosition.y - enemy.position.y
        let distance = hypot(dx, dy)
        guard distance > 1 else { return }

        // Maintain preferred distance.
        if distance < preferredDistance - distanceTolerance {
            enemy.physicsBody?.velocity = CGVector(dx: -dx / distance * moveSpeed,
                                                   dy: -dy / distance * moveSpeed)
        } else if distance > preferredDistance + distanceTolerance {
            enemy.physicsBody?.velocity = CGVector(dx: dx / distance * moveSpeed,
                                                   dy: dy / distance * moveSpeed)
        } else {
            enemy.physicsBody?.velocity = .zero
        }

        // Fire on cooldown.
        timeUntilNextShot -= deltaTime
        if timeUntilNextShot <= 0, let scene = enemy.scene {
            timeUntilNextShot = attackInterval
            let projectile = EnemyProjectileNode(damage: projectileDamage)
            projectile.position = enemy.position
            scene.addChild(projectile)
            projectile.fire(direction: CGVector(dx: dx / distance, dy: dy / distance),
                            speed: projectileSpeed)
        }
    }
}

/// Enemy shot: slow red orb the hero must dodge. Self-removes after its
/// lifetime so strays never accumulate.
final class EnemyProjectileNode: SKNode {

    let damage: Int

    init(damage: Int) {
        self.damage = damage

        super.init()

        let body = SKShapeNode(circleOfRadius: 7)
        body.fillColor = SKColor(red: 0.9, green: 0.3, blue: 0.35, alpha: 1)
        body.strokeColor = .white
        body.lineWidth = 1
        addChild(body)

        let physics = SKPhysicsBody(circleOfRadius: 7)
        physics.categoryBitMask = PhysicsCategory.enemyProjectile
        physics.contactTestBitMask = PhysicsCategory.hero | PhysicsCategory.wall
        physics.collisionBitMask = 0
        physics.affectedByGravity = false
        physics.linearDamping = 0
        physicsBody = physics
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fire(direction: CGVector, speed: CGFloat, lifetime: TimeInterval = 4) {
        physicsBody?.velocity = CGVector(dx: direction.dx * speed,
                                         dy: direction.dy * speed)
        run(.sequence([.wait(forDuration: lifetime), .removeFromParent()]))
    }
}
