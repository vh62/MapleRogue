import SpriteKit

/// Exit door at the top of the room. Spawns closed; call `open()` when the
/// room is cleared. Touching an open door triggers the room transition.
final class DoorNode: SKNode {

    private let panel: SKShapeNode
    private(set) var isOpen = false

    override init() {
        panel = SKShapeNode(rectOf: CGSize(width: 120, height: 24), cornerRadius: 6)
        panel.fillColor = SKColor(white: 0.25, alpha: 1)
        panel.strokeColor = SKColor(white: 0.5, alpha: 1)
        panel.lineWidth = 2

        super.init()
        addChild(panel)

        let physics = SKPhysicsBody(rectangleOf: CGSize(width: 120, height: 24))
        physics.isDynamic = false
        physics.categoryBitMask = PhysicsCategory.door
        physics.contactTestBitMask = PhysicsCategory.hero
        physics.collisionBitMask = 0
        physicsBody = physics
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        panel.fillColor = SKColor(red: 0.95, green: 0.8, blue: 0.2, alpha: 1)
        panel.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.6, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5),
        ])))
    }
}
