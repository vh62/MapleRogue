import SpriteKit

/// Physics categories shared across the game.
enum PhysicsCategory {
    static let hero: UInt32       = 1 << 0
    static let enemy: UInt32      = 1 << 1
    static let projectile: UInt32 = 1 << 2
    static let wall: UInt32       = 1 << 3
    static let door: UInt32       = 1 << 4
    static let enemyProjectile: UInt32 = 1 << 5
}

final class HeroNode: SKNode, Damageable {

    var moveSpeed: CGFloat                // points per second at full joystick push

    private(set) var health: Health
    private let body: SKShapeNode
    private let baseColor: SKColor
    private var facing: CGVector = CGVector(dx: 0, dy: 1)

    init(maxHP: Int = 100, moveSpeed: CGFloat = 260, color: SKColor = .orange) {
        self.health = Health(max: maxHP)
        self.moveSpeed = moveSpeed
        self.baseColor = color

        // Placeholder sprite: class-colored circle with a "nose" showing facing.
        body = SKShapeNode(circleOfRadius: 22)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 2

        super.init()
        addChild(body)

        let nose = SKShapeNode(circleOfRadius: 6)
        nose.fillColor = .white
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: 18)
        body.addChild(nose)

        let physics = SKPhysicsBody(circleOfRadius: 22)
        physics.categoryBitMask = PhysicsCategory.hero
        physics.contactTestBitMask = PhysicsCategory.enemy
        physics.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.enemy
        physics.allowsRotation = false
        physics.linearDamping = 8   // stops quickly when input ends
        physicsBody = physics
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Call every frame from GameScene.update with the joystick's velocity.
    func move(input: CGVector) {
        guard let physics = physicsBody else { return }

        physics.velocity = CGVector(dx: input.dx * moveSpeed,
                                    dy: input.dy * moveSpeed)

        // Rotate the sprite to face movement direction when moving.
        let magnitude = hypot(input.dx, input.dy)
        if magnitude > 0.1 {
            facing = input
            body.zRotation = atan2(input.dy, input.dx) - .pi / 2
        }
    }

    func increaseMaxHP(by amount: Int) {
        health.increaseMax(by: amount)
    }

    func applyDamage(_ amount: Int) {
        health.takeDamage(amount)
        // Hit flash
        body.run(.sequence([
            .run { [body] in body.fillColor = .white },
            .wait(forDuration: 0.08),
            .run { [body, baseColor] in body.fillColor = baseColor },
        ]))
    }
}
