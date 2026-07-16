import SpriteKit

/// A pooled projectile. Configure via `fire`, returned to the pool by ProjectilePool.
final class ProjectileNode: SKNode {

    private(set) var damage: Int = 0
    private(set) var isCrit: Bool = false
    /// Enemies this shot can still pass through before being recycled.
    private(set) var pierceRemaining: Int = 0
    private let body: SKShapeNode

    override init() {
        body = SKShapeNode(circleOfRadius: 8)
        body.fillColor = .cyan
        body.strokeColor = .white
        body.lineWidth = 1

        super.init()
        addChild(body)

        let physics = SKPhysicsBody(circleOfRadius: 8)
        physics.categoryBitMask = PhysicsCategory.projectile
        physics.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.wall
        physics.collisionBitMask = 0          // passes through; contacts only
        physics.affectedByGravity = false
        physics.linearDamping = 0
        physicsBody = physics
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Registers a hit on an enemy. Returns true if the shot keeps flying (pierce).
    func registerEnemyHit() -> Bool {
        guard pierceRemaining > 0 else { return false }
        pierceRemaining -= 1
        return true
    }

    func fire(from origin: CGPoint, direction: CGVector, speed: CGFloat,
              damage: Int, pierce: Int = 0, isCrit: Bool = false) {
        self.damage = damage
        self.pierceRemaining = pierce
        self.isCrit = isCrit
        // Crits read as bigger, brighter shots even before the number lands.
        body.fillColor = isCrit ? SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1) : .cyan
        setScale(isCrit ? 1.35 : 1.0)
        position = origin
        isHidden = false
        let magnitude = hypot(direction.dx, direction.dy)
        guard magnitude > 0 else { return }
        physicsBody?.velocity = CGVector(dx: direction.dx / magnitude * speed,
                                         dy: direction.dy / magnitude * speed)
    }

    func deactivate() {
        physicsBody?.velocity = .zero
        isHidden = true
        removeFromParent()
    }
}
