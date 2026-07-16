import SpriteKit

/// Slime: wanders idly until the hero comes near, then hops toward them —
/// sloppily. Each hop has aim jitter so slimes lurch rather than home in.
struct SlimeBehavior: EnemyBehavior {

    let hopImpulse: CGFloat
    let hopInterval: TimeInterval
    let aggroRadius: CGFloat
    /// Max deviation from the true direction per hop, in radians.
    let aimJitter: CGFloat

    private final class HopState {
        var timeUntilNextHop: TimeInterval = .random(in: 0...0.9)
    }
    private let state = HopState()

    init(hopImpulse: CGFloat = 55,
         hopInterval: TimeInterval = 1.2,
         aggroRadius: CGFloat = 320,
         aimJitter: CGFloat = .pi / 5) {   // ±36°
        self.hopImpulse = hopImpulse
        self.hopInterval = hopInterval
        self.aggroRadius = aggroRadius
        self.aimJitter = aimJitter
    }

    func update(enemy: EnemyNode, heroPosition: CGPoint, deltaTime: TimeInterval) {
        state.timeUntilNextHop -= deltaTime
        guard state.timeUntilNextHop <= 0 else { return }
        // Random variance so groups don't hop in sync.
        state.timeUntilNextHop = hopInterval * .random(in: 0.8...1.3)

        let dx = heroPosition.x - enemy.position.x
        let dy = heroPosition.y - enemy.position.y
        let distance = hypot(dx, dy)

        let angle: CGFloat
        if distance <= aggroRadius && distance > 1 {
            // Chase, but sloppily.
            angle = atan2(dy, dx) + .random(in: -aimJitter...aimJitter)
        } else {
            // Out of aggro range: wander in a random direction.
            angle = .random(in: -.pi ... .pi)
        }

        enemy.physicsBody?.applyImpulse(CGVector(dx: cos(angle) * hopImpulse,
                                                 dy: sin(angle) * hopImpulse))

        // Squash-and-stretch for hop feel.
        enemy.run(.sequence([
            .scaleY(to: 1.2, duration: 0.1),
            .scaleY(to: 1.0, duration: 0.15),
        ]))
    }
}

/// Factory for enemy types — keeps tuning numbers in one place.
enum EnemyFactory {
    static func slime() -> EnemyNode {
        EnemyNode(health: Health(max: 30),
                  contactDamage: 10,
                  goldValue: 5,
                  xpValue: 2,
                  behavior: SlimeBehavior(),
                  radius: 18,
                  color: SKColor(red: 0.4, green: 0.75, blue: 0.35, alpha: 1))
    }

    static func mushroom() -> EnemyNode {
        EnemyNode(health: Health(max: 50),
                  contactDamage: 15,
                  goldValue: 12,
                  xpValue: 5,
                  behavior: MushroomBehavior(),
                  radius: 20,
                  color: SKColor(red: 0.85, green: 0.45, blue: 0.3, alpha: 1))
    }

    static func boogie() -> EnemyNode {
        EnemyNode(health: Health(max: 20),
                  contactDamage: 8,
                  goldValue: 10,
                  xpValue: 4,
                  behavior: BoogieBehavior(),
                  radius: 15,
                  color: SKColor(red: 0.55, green: 0.4, blue: 0.8, alpha: 1))
    }
}
