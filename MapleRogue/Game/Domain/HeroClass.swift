import Foundation

/// A playable class: base stats the run starts from. Pure domain.
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

    static let all: [HeroClass] = [
        HeroClass(id: "dark_knight",
                  name: "Dark Knight",
                  blurb: "Durable bruiser. Hits hard, holds the line.",
                  maxHP: 130, baseDamage: 14, attackInterval: 0.6, moveSpeed: 250,
                  unlockCost: 0,
                  color: HeroClass.RGB(r: 0.85, g: 0.25, b: 0.3)),

        HeroClass(id: "bowmaster",
                  name: "Bowmaster",
                  blurb: "Fast, steady arrows. The consistent choice.",
                  maxHP: 90, baseDamage: 11, attackInterval: 0.38, moveSpeed: 270,
                  unlockCost: 500,
                  color: HeroClass.RGB(r: 0.3, g: 0.8, b: 0.5)),

        HeroClass(id: "arch_mage",
                  name: "Arch Mage",
                  blurb: "Slow, devastating orbs. Glass cannon.",
                  maxHP: 80, baseDamage: 18, attackInterval: 0.65, moveSpeed: 255,
                  unlockCost: 500,
                  color: HeroClass.RGB(r: 0.6, g: 0.4, b: 0.95)),

        HeroClass(id: "night_lord",
                  name: "Night Lord",
                  blurb: "A blur of stars. Fastest hands, thinnest armor.",
                  maxHP: 85, baseDamage: 9, attackInterval: 0.3, moveSpeed: 290,
                  unlockCost: 1000,
                  color: HeroClass.RGB(r: 0.55, g: 0.6, b: 0.7)),

        HeroClass(id: "buccaneer",
                  name: "Buccaneer",
                  blurb: "Close-range haymakers. High risk, big fists.",
                  maxHP: 120, baseDamage: 16, attackInterval: 0.55, moveSpeed: 240,
                  unlockCost: 1000,
                  color: HeroClass.RGB(r: 1.0, g: 0.6, b: 0.2)),
    ]

    static func byID(_ id: String) -> HeroClass {
        all.first { $0.id == id } ?? all[0]
    }
}
