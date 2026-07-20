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

    init(hopImpulse: CGFloat = 34,
         hopInterval: TimeInterval = 1.7,
         aggroRadius: CGFloat = 320,
         aimJitter: CGFloat = .pi / 9) {   // ±20°
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
            enemy.physicsBody?.applyImpulse(CGVector(dx: cos(angle) * hopImpulse,
                                                     dy: sin(angle) * hopImpulse))
        } else {
            // Out of aggro range: meander gently in a random direction.
            let wander = CGFloat.random(in: -.pi ... .pi)
            enemy.physicsBody?.applyImpulse(CGVector(dx: cos(wander) * hopImpulse * 0.5,
                                                     dy: sin(wander) * hopImpulse * 0.5))
        }

        // Squash-and-stretch for hop feel.
        enemy.run(.sequence([
            .scaleY(to: 1.2, duration: 0.1),
            .scaleY(to: 1.0, duration: 0.15),
        ]))
    }
}

/// Factory for enemy types — keeps tuning numbers in one place.
enum EnemyFactory {

    /// Elite variants: 3x HP, bigger, meaner, 4x gold, 3x XP.
    private static func scaled(_ base: Int, elite: Bool, by factor: Int) -> Int {
        elite ? base * factor : base
    }

    static func slime(elite: Bool = false) -> EnemyNode {
        EnemyNode(health: Health(max: scaled(30, elite: elite, by: 3)),
                  contactDamage: scaled(10, elite: elite, by: 2),
                  goldValue: scaled(5, elite: elite, by: 4),
                  xpValue: scaled(2, elite: elite, by: 3),
                  isElite: elite,
                  behavior: SlimeBehavior(),
                  radius: elite ? 27 : 18,
                  color: SKColor(red: 0.4, green: 0.75, blue: 0.35, alpha: 1))
    }

    static func mushroom(elite: Bool = false) -> EnemyNode {
        EnemyNode(health: Health(max: scaled(50, elite: elite, by: 3)),
                  contactDamage: scaled(15, elite: elite, by: 2),
                  goldValue: scaled(12, elite: elite, by: 4),
                  xpValue: scaled(5, elite: elite, by: 3),
                  isElite: elite,
                  behavior: MushroomBehavior(),
                  radius: elite ? 30 : 20,
                  color: SKColor(red: 0.85, green: 0.45, blue: 0.3, alpha: 1))
    }

    static func boogie(elite: Bool = false) -> EnemyNode {
        EnemyNode(health: Health(max: scaled(20, elite: elite, by: 3)),
                  contactDamage: scaled(8, elite: elite, by: 2),
                  goldValue: scaled(10, elite: elite, by: 4),
                  xpValue: scaled(4, elite: elite, by: 3),
                  isElite: elite,
                  behavior: BoogieBehavior(),
                  radius: elite ? 23 : 15,
                  color: SKColor(red: 0.55, green: 0.4, blue: 0.8, alpha: 1))
    }
}
