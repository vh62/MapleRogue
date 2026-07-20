import Foundation
import Combine

/// Bridge between the SpriteKit game and SwiftUI.
/// The scene pushes state changes in; SwiftUI observes and renders the HUD.
final class GameViewModel: ObservableObject {

    enum Phase {
        case playing
        case paused
        case skillChoice
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
    /// Non-nil while a boss fight is active.
    @Published private(set) var bossHealthFraction: Double?
    @Published private(set) var bossName: String = ""
    @Published private(set) var offeredSkills: [SkillDefinition] = []
    @Published private(set) var acquiredSkills: [SkillDefinition] = []

    private var wallet = Wallet()
    private var skillChooser = SkillChooser()

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

    // MARK: - Run stats (balance instrumentation + run summary)

    @Published private(set) var kills: Int = 0
    @Published private(set) var damageDealt: Int = 0
    @Published private(set) var damageTaken: Int = 0
    private var runStart = Date()
    private var roomStart = Date()
    private(set) var roomDurations: [TimeInterval] = []

    var runDuration: TimeInterval { Date().timeIntervalSince(runStart) }
    var averageRoomTime: TimeInterval {
        roomDurations.isEmpty ? 0 : roomDurations.reduce(0, +) / Double(roomDurations.count)
    }

    func recordKill() { kills += 1 }
    func recordDamageDealt(_ amount: Int) { damageDealt += amount }
    func recordDamageTaken(_ amount: Int) { damageTaken += amount }

    func recordRoomCleared() {
        roomDurations.append(Date().timeIntervalSince(roomStart))
        roomStart = Date()
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

    // MARK: - Skill choice (pick 1 of 3, Archero-style)

    func beginSkillChoice() {
        offeredSkills = skillChooser.offer(from: SkillRegistry.all)
        phase = .skillChoice
    }

    func chooseSkill(_ skill: SkillDefinition) {
        guard offeredSkills.contains(where: { $0.id == skill.id }) else { return }
        acquiredSkills.append(skill)
        onSkillAcquired?(skill)
        finishSkillChoice()
    }

    /// Grants nothing — for when every offer would be a dead pick.
    func skipSkillChoice() {
        finishSkillChoice()
    }

    private func finishSkillChoice() {
        offeredSkills = []
        phase = .playing
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
        offeredSkills = []
        acquiredSkills = []
        bossHealthFraction = nil
        runBanked = false
        runXP = 0
        leveledUpTo = nil
        kills = 0
        damageDealt = 0
        damageTaken = 0
        roomDurations = []
        runStart = Date()
        roomStart = Date()
        onRestartRequested?()
    }
}
