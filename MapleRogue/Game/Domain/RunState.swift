import Foundation

/// Pure domain model for a roguelite run's progress. No SpriteKit.
struct RunState {
    let totalRooms: Int
    private(set) var currentRoom: Int = 1

    init(totalRooms: Int = 8) {
        self.totalRooms = totalRooms
    }

    var isFinalRoom: Bool { currentRoom >= totalRooms }

    mutating func advance() {
        currentRoom = Swift.min(currentRoom + 1, totalRooms)
    }
}
