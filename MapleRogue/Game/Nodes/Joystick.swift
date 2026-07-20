import SpriteKit

/// Floating virtual joystick (Archero-style): invisible until the player
/// touches anywhere in its catch area, then the base appears under their
/// thumb and the knob tracks the drag. Read `velocity` each frame.
final class Joystick: SKNode {

    private let base: SKShapeNode
    private let knob: SKShapeNode
    private let stick: SKNode
    private let radius: CGFloat
    /// Touch catch area, centered on this node's position.
    private let catchSize: CGSize

    /// Direction and magnitude of input. Zero when untouched.
    /// x/y each in [-1, 1].
    private(set) var velocity: CGVector = .zero

    private var trackedTouch: UITouch?

    init(radius: CGFloat = 70, catchSize: CGSize = CGSize(width: 750, height: 550)) {
        self.radius = radius
        self.catchSize = catchSize

        base = SKShapeNode(circleOfRadius: radius)
        base.fillColor = SKColor(white: 1.0, alpha: 0.15)
        base.strokeColor = SKColor(white: 1.0, alpha: 0.4)
        base.lineWidth = 2

        knob = SKShapeNode(circleOfRadius: radius * 0.45)
        knob.fillColor = SKColor(white: 1.0, alpha: 0.5)
        knob.strokeColor = .clear

        stick = SKNode()

        super.init()

        isUserInteractionEnabled = true
        zPosition = 1000

        // Invisible pad guarantees SpriteKit routes touches to this node —
        // an empty node has no frame to hit-test against.
        let catchPad = SKShapeNode(rectOf: catchSize)
        catchPad.fillColor = SKColor(white: 0, alpha: 0.001)
        catchPad.strokeColor = .clear
        addChild(catchPad)

        stick.addChild(base)
        stick.addChild(knob)
        stick.isHidden = true
        addChild(stick)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The node itself has no drawn content, so SpriteKit needs an explicit
    /// hit area for touch delivery.
    override func contains(_ point: CGPoint) -> Bool {
        let local = convert(point, from: parent ?? self)
        return abs(local.x) <= catchSize.width / 2 && abs(local.y) <= catchSize.height / 2
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackedTouch == nil, let touch = touches.first else { return }
        trackedTouch = touch

        // Base appears under the thumb.
        stick.position = touch.location(in: self)
        stick.isHidden = false
        knob.position = .zero
        velocity = .zero
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackedTouch, touches.contains(touch) else { return }
        updateKnob(to: touch.location(in: stick))
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
        stick.isHidden = true
        knob.position = .zero
    }
}
