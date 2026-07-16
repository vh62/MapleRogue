import SpriteKit

/// MapleStory-style floating damage number: white for normal hits,
/// big yellow for crits. Self-removing — fire and forget.
enum DamageNumber {

    static func show(_ roll: DamageRoll, at position: CGPoint, in scene: SKScene) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "\(roll.amount)"
        label.fontSize = roll.isCrit ? 26 : 17
        label.fontColor = roll.isCrit
            ? SKColor(red: 1, green: 0.85, blue: 0.25, alpha: 1)
            : .white
        label.position = CGPoint(x: position.x + .random(in: -12...12),
                                 y: position.y + 24)
        label.zPosition = 900
        scene.addChild(label)

        var actions: [SKAction] = []
        if roll.isCrit {
            label.setScale(0.3)
            actions.append(.scale(to: 1.15, duration: 0.12))
            actions.append(.scale(to: 1.0, duration: 0.08))
        }
        actions.append(.group([
            .moveBy(x: 0, y: 34, duration: 0.6),
            .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.3)]),
        ]))
        actions.append(.removeFromParent())
        label.run(.sequence(actions))
    }
}
