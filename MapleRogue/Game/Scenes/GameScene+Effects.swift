import SpriteKit

// Game-feel effects: hit-stop, camera shake, death particles.
// Presentation-only — no game state is touched here.
extension GameScene {

    /// Brief global slow-motion frame — makes big hits register physically.
    func hitStop(duration: TimeInterval) {
        guard speed == 1 else { return }   // don't stack
        speed = 0.05
        physicsWorld.speed = 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.speed = 1
            self?.physicsWorld.speed = 1
        }
    }

    func shakeCamera(intensity: CGFloat = 14, duration: TimeInterval = 0.35) {
        guard let cameraNode = camera else { return }
        let shakes = (0..<6).map { index in
            let decay = 1 - CGFloat(index) / 6
            return SKAction.moveBy(x: .random(in: -intensity...intensity) * decay,
                                   y: .random(in: -intensity...intensity) * decay,
                                   duration: duration / 6)
        }
        cameraNode.run(.sequence(shakes))
    }

    /// Small circle burst on enemy death — cheap particles, no .sks assets.
    func spawnDeathBurst(at position: CGPoint, count: Int = 8) {
        for _ in 0..<count {
            let shard = SKShapeNode(circleOfRadius: .random(in: 2...4))
            shard.fillColor = SKColor(red: 0.5, green: 0.85, blue: 0.4, alpha: 1)
            shard.strokeColor = .clear
            shard.position = position
            shard.zPosition = 850
            addChild(shard)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...70)
            shard.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.35),
                    .fadeOut(withDuration: 0.35),
                    .scale(to: 0.2, duration: 0.35),
                ]),
                .removeFromParent(),
            ]))
        }
    }
}
