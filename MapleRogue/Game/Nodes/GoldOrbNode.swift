import SpriteKit

/// A dropped gold orb. No physics body — the scene's update loop handles
/// magnet attraction and collection by distance, which is cheaper and
/// avoids contact-handling noise.
final class GoldOrbNode: SKNode {

    let value: Int

    init(value: Int) {
        self.value = value
        super.init()

        let body = SKShapeNode(circleOfRadius: 7)
        body.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1)
        body.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 0.1, alpha: 1)
        body.lineWidth = 2
        addChild(body)

        // Gentle bob so drops feel alive.
        body.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.4),
            .scale(to: 1.0, duration: 0.4),
        ])))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Scatter outward from the death position, then settle.
    func scatter(from origin: CGPoint) {
        position = origin
        let offset = CGPoint(x: .random(in: -40...40), y: .random(in: -40...40))
        run(.move(by: CGVector(dx: offset.x, dy: offset.y), duration: 0.25))
    }
}
