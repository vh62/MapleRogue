import SpriteKit

/// How an enemy decides to move each frame. Strategy pattern — new enemy
/// types add a behavior, they don't subclass rendering code.
protocol EnemyBehavior {
    func update(enemy: EnemyNode, heroPosition: CGPoint, deltaTime: TimeInterval)
}

/// View-layer enemy node. Combat state lives in the `Health` domain model;
/// movement is delegated to an injected `EnemyBehavior`.
final class EnemyNode: SKNode, Damageable {

    private(set) var health: Health
    let contactDamage: Int
    let goldValue: Int
    let xpValue: Int
    let isElite: Bool
    private let behavior: EnemyBehavior
    private let body: SKShapeNode
    private let baseColor: SKColor

    var onDeath: ((EnemyNode) -> Void)?
    /// Fired after every damage application — the boss health bar hangs off this.
    var onHealthChanged: ((Health) -> Void)?

    init(health: Health,
         contactDamage: Int,
         goldValue: Int,
         xpValue: Int = 2,
         isElite: Bool = false,
         behavior: EnemyBehavior,
         radius: CGFloat,
         color: SKColor) {
        self.health = health
        self.contactDamage = contactDamage
        self.goldValue = goldValue
        self.xpValue = xpValue
        self.isElite = isElite
        self.behavior = behavior
        self.baseColor = color

        body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = color
        // Elites read instantly: gold outline, thicker stroke.
        body.strokeColor = isElite ? SKColor(red: 1, green: 0.85, blue: 0.25, alpha: 1) : .white
        body.lineWidth = isElite ? 3.5 : 1.5

        super.init()
        addChild(body)

        let physics = SKPhysicsBody(circleOfRadius: radius)
        physics.categoryBitMask = PhysicsCategory.enemy
        physics.contactTestBitMask = PhysicsCategory.hero | PhysicsCategory.projectile
        physics.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.enemy | PhysicsCategory.hero
        physics.allowsRotation = false
        physics.linearDamping = 4
        physicsBody = physics
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(heroPosition: CGPoint, deltaTime: TimeInterval) {
        behavior.update(enemy: self, heroPosition: heroPosition, deltaTime: deltaTime)
    }

    func applyDamage(_ amount: Int) {
        health.takeDamage(amount)
        onHealthChanged?(health)

        body.run(.sequence([
            .run { [body, baseColor] in body.fillColor = .white; _ = baseColor },
            .wait(forDuration: 0.06),
            .run { [body, baseColor] in body.fillColor = baseColor },
        ]))

        if health.isDead {
            die()
        }
    }

    private func die() {
        onDeath?(self)
        physicsBody = nil
        run(.sequence([
            .group([.scale(to: 0.1, duration: 0.15), .fadeOut(withDuration: 0.15)]),
            .removeFromParent(),
        ]))
    }
}
