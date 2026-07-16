import Foundation
import Combine

/// Bridge between the SpriteKit game and SwiftUI.
/// The scene pushes state changes in; SwiftUI observes and renders the HUD.
final class GameViewModel: ObservableObject {

    enum Phase {
        case playing
        case paused
        case gacha
        case dead
        case victory
    }

    @Published private(set) var heroHealthFraction: Double = 1.0
    @Published private(set) var heroHP: Int = 100
    @Published private(set) var heroMaxHP: Int = 100
    @Published private(set) var currentRoom: Int = 1
    @Published private(set) var totalRooms: Int = 8
    @Published private(set) var phase: Phase = .playing
    @Published private(set) var gold: Int = 0
    @Published private(set) var skillTokens: Int = 0
    /// Non-nil while a boss fight is active.
    @Published private(set) var bossHealthFraction: Double?
    @Published private(set) var bossName: String = ""
    @Published private(set) var lastPull: SkillDefinition?
    @Published private(set) var acquiredSkills: [SkillDefinition] = []

    private var wallet = Wallet()
    private let gachaMachine = GachaMachine()

    var pullsUntilPity: Int { gachaMachine.pullsUntilPity }

    /// Set by the scene: applies a pulled skill to the live run.
    var onSkillAcquired: ((SkillDefinition) -> Void)?
    /// Set by the scene: resumes the run after the gacha closes.
    var onGachaDismissed: (() -> Void)?
    /// Set by the scene: freezes/unfreezes the SpriteKit scene.
    var onPauseChanged: ((Bool) -> Void)?

    /// Set by the container view; called when the player taps Restart.
    var onRestartRequested: (() -> Void)?
    /// Set by the container view; banks run results into the profile.
    /// Called once per run with (goldEarned, xpEarned, roomReached, victory).
    var onRunEnded: ((Int, Int, Int, Bool) -> Void)?
    private var runBanked = false

    @Published private(set) var runXP: Int = 0
    /// Set after banking when the account leveled up (new level number).
    @Published var leveledUpTo: Int?

    func xpEarned(_ amount: Int) {
        runXP += amount
    }

    // MARK: - Scene-facing updates

    func heroHealthChanged(_ health: Health) {
        heroHP = health.current
        heroMaxHP = health.max
        heroHealthFraction = health.fraction
        if health.isDead {
            phase = .dead
            bankRunOnce(victory: false)
        }
    }

    private func bankRunOnce(victory: Bool) {
        guard !runBanked else { return }
        runBanked = true
        if victory { runXP += XPReward.runCompleted }
        // On victory all rooms cleared; on death the current room wasn't.
        onRunEnded?(gold, runXP, victory ? totalRooms : currentRoom - 1, victory)
    }

    func roomChanged(current: Int, total: Int) {
        currentRoom = current
        totalRooms = total
    }

    func runCompleted() {
        phase = .victory
        bankRunOnce(victory: true)
    }

    func goldCollected(_ amount: Int) {
        wallet.add(amount)
        gold = wallet.gold
    }

    // MARK: - Boss

    func bossAppeared(name: String) {
        bossName = name
        bossHealthFraction = 1.0
    }

    func bossHealthChanged(_ health: Health) {
        bossHealthFraction = health.isDead ? nil : health.fraction
    }

    // MARK: - Pause

    func pause() {
        guard phase == .playing else { return }
        phase = .paused
        onPauseChanged?(true)
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        onPauseChanged?(false)
    }

    /// Leaving mid-run still banks what was earned — quitting shouldn't
    /// feel like losing your gold.
    func abandonRun() {
        bankRunOnce(victory: false)
    }

    // MARK: - Gacha

    func tokenEarned(_ count: Int = 1) {
        skillTokens += count
    }

    func beginGacha() {
        lastPull = nil
        phase = .gacha
    }

    func pullSkill() {
        guard skillTokens > 0 else { return }
        skillTokens -= 1
        let skill = gachaMachine.pull(from: SkillRegistry.all)
        lastPull = skill
        acquiredSkills.append(skill)
        onSkillAcquired?(skill)
    }

    func finishGacha() {
        phase = .playing
        lastPull = nil
        onGachaDismissed?()
    }

    // MARK: - UI-facing actions

    func restart() {
        phase = .playing
        heroHealthFraction = 1.0
        heroHP = heroMaxHP
        currentRoom = 1
        wallet = Wallet()
        gold = 0
        skillTokens = 0
        lastPull = nil
        acquiredSkills = []
        bossHealthFraction = nil
        runBanked = false
        runXP = 0
        leveledUpTo = nil
        onRestartRequested?()
    }
}
