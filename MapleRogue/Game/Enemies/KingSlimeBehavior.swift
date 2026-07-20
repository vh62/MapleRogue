import SpriteKit

/// King Slime: two-phase boss.
/// Phase 1 (HP > 50%): heavy, slow hops toward the hero.
/// At 50%: summons a ring of minion slimes (once).
/// Phase 2 (HP ≤ 50%): faster hops plus radial projectile volleys.
final class KingSlimeBehavior: EnemyBehavior {

    /// Set by the scene — spawning minions needs to register them with
    /// the room's enemy list, which the behavior knows nothing about.
    var onSummonMinions: ((CGPoint) -> Void)?

    private var didSummon = false
    private var timeUntilNextHop: TimeInterval = 1.2
    private var timeUntilNextVolley: TimeInterval = 2.0

    // Tunables
    let hopImpulse: CGFloat = 640           // boss body is heavy
    let volleyProjectiles = 8
    let volleyInterval: TimeInterval = 2.5
    let volleySpeed: CGFloat = 165
    let volleyDamage = 10

    func update(enemy: EnemyNode, heroPosition: CGPoint, deltaTime: TimeInterval) {
        let enraged = enemy.health.fraction <= 0.5

        if enraged && !didSummon {
            didSummon = true
            onSummonMinions?(enemy.position)
        }

        hop(enemy: enemy, heroPosition: heroPosition, deltaTime: deltaTime, enraged: enraged)

        if enraged {
            volley(from: enemy, deltaTime: deltaTime)
        }
    }

    private func hop(enemy: EnemyNode, heroPosition: CGPoint,
                     deltaTime: TimeInterval, enraged: Bool) {
        timeUntilNextHop -= deltaTime
        guard timeUntilNextHop <= 0 else { return }
        timeUntilNextHop = enraged ? 1.3 : 2.0

        let dx = heroPosition.x - enemy.position.x
        let dy = heroPosition.y - enemy.position.y
        let distance = hypot(dx, dy)
        guard distance > 1 else { return }

        enemy.physicsBody?.applyImpulse(CGVector(dx: dx / distance * hopImpulse,
                                                 dy: dy / distance * hopImpulse))
        enemy.run(.sequence([
            .scaleY(to: 1.25, duration: 0.12),
            .scaleY(to: 0.9, duration: 0.1),
            .scaleY(to: 1.0, duration: 0.12),
        ]))
    }

    private func volley(from enemy: EnemyNode, deltaTime: TimeInterval) {
        timeUntilNextVolley -= deltaTime
        guard timeUntilNextVolley <= 0, let scene = enemy.scene else { return }
        timeUntilNextVolley = volleyInterval

        for index in 0..<volleyProjectiles {
            let angle = CGFloat(index) / CGFloat(volleyProjectiles) * 2 * .pi
            let shot = EnemyProjectileNode(damage: volleyDamage)
            shot.position = enemy.position
            scene.addChild(shot)
            shot.fire(direction: CGVector(dx: cos(angle), dy: sin(angle)),
                      speed: volleySpeed)
        }
    }
}

extension EnemyFactory {
    static func kingSlime(behavior: KingSlimeBehavior) -> EnemyNode {
        EnemyNode(health: Health(max: 600),
                  contactDamage: 20,
                  goldValue: 100,
                  xpValue: 150,
                  behavior: behavior,
                  radius: 55,
                  color: SKColor(red: 0.3, green: 0.6, blue: 0.85, alpha: 1))
    }
}
