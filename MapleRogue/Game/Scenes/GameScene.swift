import SpriteKit

final class GameScene: SKScene {

    private let viewModel: GameViewModel
    private let heroClass: HeroClass
    /// Meta-progression contribution (gear levels, stars, cube potentials).
    private let build: HeroBuild
    /// Class base damage with the build's ATK bonus applied.
    private let baseDamage: Int

    private var hero: HeroNode!
    private var cameraNode: SKCameraNode!
    private var joystick: Joystick!
    private var door: DoorNode!

    init(viewModel: GameViewModel,
         size: CGSize,
         heroClass: HeroClass = ClassRegistry.all[0],
         build: HeroBuild = HeroBuild()) {
        self.viewModel = viewModel
        self.heroClass = heroClass
        self.build = build
        self.baseDamage = heroClass.baseDamage + heroClass.baseDamage * build.atkPercent / 100
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let projectilePool = ProjectilePool()
    private lazy var autoAttack = AutoAttackSystem(pool: projectilePool)
    private lazy var waveSpawner = WaveSpawner(roomRect: roomRect)
    private var enemies: [EnemyNode] = []
    private let goldOrbs = GoldOrbSystem()
    private var runState = RunState(totalRooms: 8)
    private var loadout = HeroLoadout()
    private var obstacleNodes: [SKNode] = []

    private var lastUpdateTime: TimeInterval = 0
    private var heroContactCooldown: TimeInterval = 0
    private var isTransitioning = false

    private let roomSize = CGSize(width: 900, height: 900)
    private var roomRect: CGRect {
        CGRect(origin: CGPoint(x: -roomSize.width / 2, y: -roomSize.height / 2),
               size: roomSize)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.12, blue: 0.08, alpha: 1)
        physicsWorld.gravity = .zero   // top-down: no gravity
        physicsWorld.contactDelegate = self

        setupCamera()
        setupRoom()
        setupHero()
        setupJoystick()
        setupGachaCallbacks()
        applyCombatStats()
        startRoom()
    }

    // MARK: - Setup

    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
    }

    private func setupRoom() {
        let walls = SKShapeNode(rect: roomRect)
        walls.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1)
        walls.lineWidth = 6

        let wallBody = SKPhysicsBody(edgeLoopFrom: roomRect)
        wallBody.categoryBitMask = PhysicsCategory.wall
        walls.physicsBody = wallBody
        addChild(walls)

        door = DoorNode()
        door.position = CGPoint(x: 0, y: roomRect.maxY)
        addChild(door)
    }

    /// Obstacles are rebuilt every room from a random layout — same rocks
    /// eight rooms in a row was a monotony machine.
    private func buildObstacles() {
        obstacleNodes.forEach { $0.removeFromParent() }
        obstacleNodes.removeAll()

        for obstacle in RoomLayouts.random() {
            let size = CGSize(width: obstacle.width, height: obstacle.height)
            let rock = SKShapeNode(rectOf: size, cornerRadius: 12)
            rock.fillColor = SKColor(white: 0.35, alpha: 1)
            rock.strokeColor = SKColor(white: 0.5, alpha: 1)
            rock.position = CGPoint(x: obstacle.x, y: obstacle.y)

            let rockBody = SKPhysicsBody(rectangleOf: size)
            rockBody.isDynamic = false
            rockBody.categoryBitMask = PhysicsCategory.wall
            rock.physicsBody = rockBody
            addChild(rock)
            obstacleNodes.append(rock)
        }
    }

    private func setupHero() {
        hero = HeroNode(maxHP: heroClass.maxHP + build.bonusHP,
                        moveSpeed: CGFloat(heroClass.moveSpeed),
                        color: SKColor(red: heroClass.color.r,
                                       green: heroClass.color.g,
                                       blue: heroClass.color.b,
                                       alpha: 1))
        hero.position = CGPoint(x: 0, y: -300)
        addChild(hero)
        cameraNode.position = hero.position
        viewModel.heroHealthChanged(hero.health)
    }

    private func setupJoystick() {
        // Floating: the catch area spans the lower half of the screen;
        // the stick appears wherever the thumb lands.
        joystick = Joystick(catchSize: CGSize(width: size.width,
                                              height: size.height * 0.55))
        joystick.position = CGPoint(x: 0, y: -size.height * 0.22)
        cameraNode.addChild(joystick)
    }

    private func setupGachaCallbacks() {
        viewModel.onSkillAcquired = { [weak self] skill in
            self?.applySkill(skill)
        }
        viewModel.onGachaDismissed = { [weak self] in
            self?.isPaused = false
            self?.performRoomTransition()
        }
        viewModel.onPauseChanged = { [weak self] paused in
            self?.isPaused = paused
        }
    }

    private func applySkill(_ skill: SkillDefinition) {
        loadout.add(skill)
        applyCombatStats()

        if case .maxHP(let bonus) = skill.effect {
            hero.increaseMaxHP(by: bonus)
            viewModel.heroHealthChanged(hero.health)
        }
    }

    /// Combines class base + gear build + in-run skill loadout into the
    /// live combat systems. Called at setup and after every skill pickup.
    private func applyCombatStats() {
        autoAttack.damage = loadout.damage(base: baseDamage)
        autoAttack.attackInterval = loadout.attackInterval(base: heroClass.attackInterval)
        autoAttack.extraProjectiles = loadout.extraProjectiles
        autoAttack.pierceCount = loadout.pierceCount
        autoAttack.damageRoller.critChance = CombatTuning.baseCritChance
            + Double(build.critRatePercent + loadout.critRatePercent) / 100
        autoAttack.damageRoller.critMultiplier = CombatTuning.baseCritMultiplier
            + Double(build.critDmgPercent) / 100
        hero.moveSpeed = CGFloat(loadout.moveSpeed(
            base: heroClass.moveSpeed * (1.0 + Double(build.moveSpeedPercent) / 100)))
    }

    // MARK: - Room flow

    private func startRoom() {
        isTransitioning = false
        viewModel.roomChanged(current: runState.currentRoom, total: runState.totalRooms)
        hero.position = CGPoint(x: 0, y: -300)
        buildObstacles()

        if runState.isFinalRoom {
            spawnBoss()
        } else {
            enemies = waveSpawner.spawnWave(forRoom: runState.currentRoom,
                                            in: self,
                                            avoiding: hero.position) { [weak self] dead in
                self?.handleEnemyDeath(dead)
            }
        }
    }

    private func spawnBoss() {
        let behavior = KingSlimeBehavior()
        let boss = EnemyFactory.kingSlime(behavior: behavior)
        boss.position = CGPoint(x: 0, y: 250)

        behavior.onSummonMinions = { [weak self] origin in
            self?.summonMinions(around: origin)
        }
        boss.onHealthChanged = { [weak self] health in
            self?.viewModel.bossHealthChanged(health)
        }
        boss.onDeath = { [weak self] dead in
            self?.handleEnemyDeath(dead)
        }

        enemies = [boss]
        addChild(boss)
        viewModel.bossAppeared(name: "King Slime")

        // Entrance: drop in with a slam.
        boss.setScale(0.1)
        boss.run(.sequence([
            .scale(to: 1.3, duration: 0.35),
            .scale(to: 1.0, duration: 0.15),
        ]))
        SoundSystem.shared.play(.bossSlam, in: self)
        shakeCamera()
    }

    private func summonMinions(around origin: CGPoint) {
        for index in 0..<4 {
            let angle = CGFloat(index) / 4 * 2 * .pi
            let minion = EnemyFactory.slime()
            minion.position = CGPoint(x: origin.x + cos(angle) * 110,
                                      y: origin.y + sin(angle) * 110)
            minion.onDeath = { [weak self] dead in
                self?.handleEnemyDeath(dead)
            }
            enemies.append(minion)
            addChild(minion)
            minion.setScale(0.1)
            minion.run(.scale(to: 1.0, duration: 0.25))
        }
    }

    private func handleEnemyDeath(_ dead: EnemyNode) {
        enemies.removeAll { $0 === dead }
        goldOrbs.drop(from: dead, in: self)
        viewModel.xpEarned(dead.xpValue)
        viewModel.recordKill()
        if dead.isElite {
            viewModel.tokenEarned()   // elites drop a bonus skill token
        }
        if enemies.isEmpty {
            door.open()
            SoundSystem.shared.play(.doorOpen, in: self)
            viewModel.tokenEarned()   // 1 skill token per room cleared
            viewModel.xpEarned(XPReward.roomCleared)
            viewModel.recordRoomCleared()
        }
    }

    private func advanceToNextRoom() {
        guard !isTransitioning else { return }
        isTransitioning = true

        // Vacuum all remaining floor gold the moment the player exits —
        // before banking, before the gacha shows its gold count.
        let remaining = goldOrbs.collectRemaining()
        if remaining > 0 {
            SoundSystem.shared.play(.pickup, in: self)
            viewModel.goldCollected(remaining)
        }

        if runState.isFinalRoom {
            viewModel.runCompleted()
            isPaused = true
            return
        }

        // Gacha after every cleared room (when there's a token to spend) —
        // the build should evolve constantly, Archero-style.
        if viewModel.skillTokens > 0 {
            viewModel.beginGacha()
            isPaused = true
            return   // onGachaDismissed continues via performRoomTransition()
        }

        performRoomTransition()
    }

    private func performRoomTransition() {
        runState.advance()

        // Fade out/in transition, then reset the room.
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0
        overlay.zPosition = 1900
        cameraNode.addChild(overlay)

        overlay.run(.sequence([
            .fadeIn(withDuration: 0.25),
            .run { [weak self] in self?.resetRoomState() },
            .fadeOut(withDuration: 0.25),
            .removeFromParent(),
        ]))
    }

    private func resetRoomState() {
        for projectile in projectilePool.active {
            projectilePool.recycle(projectile)
        }
        // Clear any stray enemy shots from the previous room.
        for child in children where child is EnemyProjectileNode {
            child.removeFromParent()
        }
        // Safety net — advanceToNextRoom already vacuumed; this catches
        // restarts and any orbs spawned during the transition.
        viewModel.goldCollected(goldOrbs.collectRemaining())
        door = door.replacedWithClosedDoor(in: self, at: CGPoint(x: 0, y: roomRect.maxY))
        startRoom()
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        heroContactCooldown -= deltaTime

        let input = joystick.velocity
        hero.move(input: input)
        let heroIsMoving = hypot(input.dx, input.dy) > 0.1

        for enemy in enemies {
            enemy.update(heroPosition: hero.position, deltaTime: deltaTime)
        }

        autoAttack.update(deltaTime: deltaTime,
                          heroPosition: hero.position,
                          heroIsMoving: heroIsMoving,
                          enemies: enemies,
                          scene: self)

        projectilePool.cullOutOfBounds(roomRect: roomRect.insetBy(dx: -50, dy: -50))

        let goldCollected = goldOrbs.update(deltaTime: deltaTime, heroPosition: hero.position)
        if goldCollected > 0 {
            SoundSystem.shared.play(.pickup, in: self)
            viewModel.goldCollected(goldCollected)
        }

        let lerp: CGFloat = 0.12
        cameraNode.position.x += (hero.position.x - cameraNode.position.x) * lerp
        cameraNode.position.y += (hero.position.y - cameraNode.position.y) * lerp
    }
}

// MARK: - Contact handling

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let nodes = (contact.bodyA.node, contact.bodyB.node)

        switch nodes {
        case let (projectile as ProjectileNode, enemy as EnemyNode),
             let (enemy as EnemyNode, projectile as ProjectileNode):
            let wasAlive = !enemy.health.isDead
            enemy.applyDamage(projectile.damage)
            viewModel.recordDamageDealt(projectile.damage)
            DamageNumber.show(DamageRoll(amount: projectile.damage, isCrit: projectile.isCrit),
                              at: enemy.position, in: self)

            // Knockback along the shot's travel direction.
            if let velocity = projectile.physicsBody?.velocity {
                let magnitude = hypot(velocity.dx, velocity.dy)
                if magnitude > 1 {
                    let shove: CGFloat = projectile.isCrit ? 38 : 20
                    enemy.physicsBody?.applyImpulse(CGVector(dx: velocity.dx / magnitude * shove,
                                                             dy: velocity.dy / magnitude * shove))
                }
            }

            if wasAlive && enemy.health.isDead {
                SoundSystem.shared.play(.enemyDeath, in: self)
                spawnDeathBurst(at: enemy.position)
                hitStop(duration: 0.05)
            } else {
                SoundSystem.shared.play(projectile.isCrit ? .crit : .hit, in: self)
                if projectile.isCrit { hitStop(duration: 0.04) }
            }

            if !projectile.registerEnemyHit() {
                projectilePool.recycle(projectile)
            }

        case (is HeroNode, is DoorNode), (is DoorNode, is HeroNode):
            if door.isOpen { advanceToNextRoom() }

        case let (projectile as ProjectileNode, _), let (_, projectile as ProjectileNode):
            // Hit a wall.
            projectilePool.recycle(projectile)

        case let (shot as EnemyProjectileNode, hit), let (hit, shot as EnemyProjectileNode):
            shot.removeFromParent()
            if hit is HeroNode {
                damageHero(shot.damage)
            }
            // Otherwise it hit a wall — removal is enough.

        case let (enemy as EnemyNode, hero as HeroNode), let (hero as HeroNode, enemy as EnemyNode):
            guard hero === self.hero, heroContactCooldown <= 0 else { return }
            heroContactCooldown = 0.6   // invulnerability window after a hit
            damageHero(enemy.contactDamage)

        default:
            break
        }
    }

    private func damageHero(_ amount: Int) {
        hero.applyDamage(amount)
        viewModel.recordDamageTaken(amount)
        SoundSystem.shared.play(.heroHit, in: self)
        shakeCamera(intensity: 7, duration: 0.2)
        if hero.health.isDead {
            // Floor gold counts even in death — banking runs inside the
            // health-change notification, so vacuum first.
            viewModel.goldCollected(goldOrbs.collectRemaining())
        }
        viewModel.heroHealthChanged(hero.health)
        if hero.health.isDead {
            isPaused = true
        }
    }
}

private extension DoorNode {
    /// Doors don't reopen; simplest reliable reset is replacing the node.
    func replacedWithClosedDoor(in scene: SKScene, at position: CGPoint) -> DoorNode {
        removeFromParent()
        let fresh = DoorNode()
        fresh.position = position
        scene.addChild(fresh)
        return fresh
    }
}
