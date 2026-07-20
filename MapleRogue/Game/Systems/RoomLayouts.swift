import Foundation

/// Hand-designed obstacle layouts, picked at random per room so no two
/// rooms in a run play the same. Coordinates are room-centered (900×900).
enum RoomLayouts {

    struct Obstacle {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    static let variants: [[Obstacle]] = [
        // Classic scatter
        [Obstacle(x: -200, y: 150, width: 80, height: 80),
         Obstacle(x: 220, y: -100, width: 80, height: 80),
         Obstacle(x: 0, y: 280, width: 80, height: 80)],

        // Center cross — forces orbiting
        [Obstacle(x: 0, y: 0, width: 220, height: 70),
         Obstacle(x: 0, y: 0, width: 70, height: 220)],

        // Twin pillars corridor
        [Obstacle(x: -160, y: 60, width: 70, height: 260),
         Obstacle(x: 160, y: -60, width: 70, height: 260)],

        // Four corners — open middle, cover at edges
        [Obstacle(x: -260, y: 260, width: 100, height: 100),
         Obstacle(x: 260, y: 260, width: 100, height: 100),
         Obstacle(x: -260, y: -260, width: 100, height: 100),
         Obstacle(x: 260, y: -260, width: 100, height: 100)],

        // Broken wall — one long barrier with a gap
        [Obstacle(x: -190, y: 90, width: 240, height: 60),
         Obstacle(x: 210, y: 90, width: 240, height: 60),
         Obstacle(x: 0, y: -240, width: 90, height: 90)],

        // Diagonal steps
        [Obstacle(x: -240, y: 240, width: 85, height: 85),
         Obstacle(x: -80, y: 80, width: 85, height: 85),
         Obstacle(x: 80, y: -80, width: 85, height: 85),
         Obstacle(x: 240, y: -240, width: 85, height: 85)],

        // Open field — no cover, pure dodging (rare breather)
        [],
    ]

    static func random() -> [Obstacle] {
        variants.randomElement() ?? []
    }
}
