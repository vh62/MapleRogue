import Foundation

/// Hand-designed obstacle layouts for tall (900×1700) traversal maps,
/// picked at random per room. Each layout places cover across the lower,
/// middle, and upper thirds so every screen of the climb has terrain.
/// Coordinates are map-centered: x ∈ [-450, 450], y ∈ [-850, 850].
enum RoomLayouts {

    struct Obstacle {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    static let variants: [[Obstacle]] = [
        // Winding scatter
        [Obstacle(x: -220, y: -550, width: 85, height: 85),
         Obstacle(x: 230, y: -380, width: 85, height: 85),
         Obstacle(x: -180, y: -60, width: 85, height: 85),
         Obstacle(x: 200, y: 180, width: 85, height: 85),
         Obstacle(x: -240, y: 420, width: 85, height: 85),
         Obstacle(x: 120, y: 640, width: 85, height: 85)],

        // Gate rows — horizontal walls with alternating gaps
        [Obstacle(x: -200, y: -420, width: 320, height: 60),
         Obstacle(x: 260, y: -420, width: 200, height: 60),
         Obstacle(x: 200, y: 60, width: 320, height: 60),
         Obstacle(x: -260, y: 60, width: 200, height: 60),
         Obstacle(x: -200, y: 520, width: 320, height: 60),
         Obstacle(x: 260, y: 520, width: 200, height: 60)],

        // Pillar corridor — center lane flanked the whole way up
        [Obstacle(x: -230, y: -500, width: 70, height: 280),
         Obstacle(x: 230, y: -500, width: 70, height: 280),
         Obstacle(x: -230, y: 80, width: 70, height: 280),
         Obstacle(x: 230, y: 80, width: 70, height: 280),
         Obstacle(x: -230, y: 620, width: 70, height: 220),
         Obstacle(x: 230, y: 620, width: 70, height: 220)],

        // Islands — big blocks to orbit, one per third
        [Obstacle(x: 0, y: -480, width: 200, height: 140),
         Obstacle(x: -190, y: 100, width: 170, height: 170),
         Obstacle(x: 190, y: 100, width: 170, height: 170),
         Obstacle(x: 0, y: 600, width: 200, height: 140)],

        // Diagonal steps climbing with the player
        [Obstacle(x: -280, y: -600, width: 90, height: 90),
         Obstacle(x: -100, y: -350, width: 90, height: 90),
         Obstacle(x: 90, y: -100, width: 90, height: 90),
         Obstacle(x: 270, y: 150, width: 90, height: 90),
         Obstacle(x: 90, y: 400, width: 90, height: 90),
         Obstacle(x: -100, y: 650, width: 90, height: 90)],

        // Cross plazas — a cross at mid-map, corners up top
        [Obstacle(x: 0, y: 40, width: 260, height: 70),
         Obstacle(x: 0, y: 40, width: 70, height: 260),
         Obstacle(x: -280, y: -520, width: 100, height: 100),
         Obstacle(x: 280, y: -520, width: 100, height: 100),
         Obstacle(x: -280, y: 600, width: 100, height: 100),
         Obstacle(x: 280, y: 600, width: 100, height: 100)],

        // Open field — no cover, pure dodging (rare breather)
        [],
    ]

    static func random() -> [Obstacle] {
        variants.randomElement() ?? []
    }
}
