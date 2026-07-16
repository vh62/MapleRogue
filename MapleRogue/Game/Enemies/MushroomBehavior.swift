import SpriteKit

/// Mushroom: waddles slowly toward the hero; when in range, stops,
/// telegraphs (puffs up), then charges in a perfectly straight line.
/// The telegraph makes the charge dodgeable — the contrast with sloppy
/// slimes is intentional.
final class MushroomBehavior: EnemyBehavior {

    private enum State {
        case approach
        case telegraph(remaining: TimeInterval, direction: CGVector)
        case cooldown(remaining: TimeInterval)
    }

    private var state: State = .approach

    let waddleSpeed: CGFloat = 40
    let chargeRange: CGFloat = 260
    let telegraphDuration: TimeInterval = 0.6
    let chargeImpulse: CGFloat = 260
    let cooldownDuration: TimeInterval = 1.6

    func update(enemy: EnemyNode, heroPosition: CGPoint, deltaTime: TimeInterval) {
        let dx = heroPosition.x - enemy.position.x
        let dy = heroPosition.y - enemy.position.y
        let distance = hypot(dx, dy)

        switch state {
        case .approach:
            guard distance > 1 else { return }
            if distance <= chargeRange {
                // Lock aim NOW — the charge goes where the hero WAS.
                let direction = CGVector(dx: dx / distance, dy: dy / distance)
                state = .telegraph(remaining: telegraphDuration, direction: direction)
                enemy.run(.sequence([
                    .scale(to: 1.35, duration: telegraphDuration * 0.8),
                    .scale(to: 1.0, duration: telegraphDuration * 0.2),
                ]))
            } else {
                enemy.physicsBody?.velocity = CGVector(dx: dx / distance * waddleSpeed,
                                                       dy: dy / distance * waddleSpeed)
            }

        case .telegraph(let remaining, let direction):
            let left = remaining - deltaTime
            if left <= 0 {
                enemy.physicsBody?.applyImpulse(CGVector(dx: direction.dx * chargeImpulse,
                                                         dy: direction.dy * chargeImpulse))
                state = .cooldown(remaining: cooldownDuration)
            } else {
                state = .telegraph(remaining: left, direction: direction)
            }

        case .cooldown(let remaining):
            let left = remaining - deltaTime
            state = left <= 0 ? .approach : .cooldown(remaining: left)
        }
    }
}
