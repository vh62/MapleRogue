import SpriteKit

/// Fire-and-forget sound effects. Actions are cached — creating a
/// playSoundFileNamed action is expensive, playing it is cheap.
enum Sound: String {
    case shoot
    case hit
    case crit
    case enemyDeath = "enemy_death"
    case pickup
    case doorOpen = "door_open"
    case heroHit = "hero_hit"
    case bossSlam = "boss_slam"
}

final class SoundSystem {

    static let shared = SoundSystem()

    var isMuted = false

    private var cache: [Sound: SKAction] = [:]

    private init() {}

    func play(_ sound: Sound, in node: SKNode) {
        guard !isMuted else { return }
        let action = cache[sound] ?? {
            let action = SKAction.playSoundFileNamed("\(sound.rawValue).wav",
                                                     waitForCompletion: false)
            cache[sound] = action
            return action
        }()
        node.run(action)
    }
}
