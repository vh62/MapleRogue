import Foundation

/// A playable hero: base stats the run starts from. Pure domain.
/// The game launches with a single hero — the class architecture stays
/// so more heroes can ship in a post-launch update without rework.
struct HeroClass: Identifiable, Equatable {

    struct RGB: Equatable {
        let r: Double, g: Double, b: Double
    }

    let id: String
    let name: String
    let blurb: String
    let maxHP: Int
    let baseDamage: Int
    let attackInterval: TimeInterval
    let moveSpeed: Double
    /// 0 = available from the start.
    let unlockCost: Int
    let color: RGB
}

enum ClassRegistry {

    /// Launch roster: one hero. Balanced ranged fighter, because the only
    /// hero must support every build the skill/gear systems can produce.
    static let all: [HeroClass] = [
        HeroClass(id: "dark_wanderer",
                  name: "Dark Wanderer",
                  blurb: "A lone shadow on the long road.",
                  maxHP: 110, baseDamage: 13, attackInterval: 0.5, moveSpeed: 260,
                  unlockCost: 0,
                  color: HeroClass.RGB(r: 0.45, g: 0.35, b: 0.6)),
    ]

    /// Unknown ids (legacy saves from the multi-class prototype) resolve
    /// to the launch hero.
    static func byID(_ id: String) -> HeroClass {
        all.first { $0.id == id } ?? all[0]
    }
}
