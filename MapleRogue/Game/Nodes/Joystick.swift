import SpriteKit

/// Virtual joystick: a fixed base circle with a draggable knob.
/// Read `velocity` each frame — a unit-ish vector scaled by how far the knob is pushed.
final class Joystick: SKNode {

    private let base: SKShapeNode
    private let knob: SKShapeNode
    private let radius: CGFloat

    /// Direction and magnitude of input. Zero when untouched.
    /// x/y each in [-1, 1].
    private(set) var velocity: CGVector = .zero

    private var trackedTouch: UITouch?

    init(radius: CGFloat = 70) {
        self.radius = radius

        base = SKShapeNode(circleOfRadius: radius)
        base.fillColor = SKColor(white: 1.0, alpha: 0.15)
        base.strokeColor = SKColor(white: 1.0, alpha: 0.4)
        base.lineWidth = 2

        knob = SKShapeNode(circleOfRadius: radius * 0.45)
        knob.fillColor = SKColor(white: 1.0, alpha: 0.5)
        knob.strokeColor = .clear

        super.init()

        isUserInteractionEnabled = true
        zPosition = 1000
        addChild(base)
        addChild(knob)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackedTouch == nil, let touch = touches.first else { return }
        trackedTouch = touch
        updateKnob(to: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackedTouch, touches.contains(touch) else { return }
        updateKnob(to: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackedTouch, touches.contains(touch) else { return }
        reset()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        reset()
    }

    // MARK: - Internals

    private func updateKnob(to location: CGPoint) {
        let distance = hypot(location.x, location.y)
        let clamped = min(distance, radius)
        let angle = atan2(location.y, location.x)

        knob.position = CGPoint(x: cos(angle) * clamped,
                                y: sin(angle) * clamped)

        let magnitude = clamped / radius
        velocity = CGVector(dx: cos(angle) * magnitude,
                            dy: sin(angle) * magnitude)
    }

    private func reset() {
        trackedTouch = nil
        velocity = .zero
        knob.run(.move(to: .zero, duration: 0.1))
    }
}
