import SpriteKit

/// Reuses projectile nodes to avoid allocation during combat.
final class ProjectilePool {

    private var available: [ProjectileNode] = []
    private(set) var active: Set<ProjectileNode> = []

    init(preload: Int = 30) {
        available = (0..<preload).map { _ in ProjectileNode() }
    }

    func spawn(in scene: SKScene) -> ProjectileNode {
        let projectile = available.popLast() ?? ProjectileNode()
        active.insert(projectile)
        scene.addChild(projectile)
        return projectile
    }

    func recycle(_ projectile: ProjectileNode) {
        guard active.remove(projectile) != nil else { return }
        projectile.deactivate()
        available.append(projectile)
    }

    /// Recycle any projectile that has wandered outside the room bounds.
    func cullOutOfBounds(roomRect: CGRect) {
        for projectile in active where !roomRect.contains(projectile.position) {
            recycle(projectile)
        }
    }
}
