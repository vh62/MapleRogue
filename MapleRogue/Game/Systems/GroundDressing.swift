import SpriteKit

/// Code-drawn ground decoration: a worn path from entrance to exit plus
/// scattered grass, flowers, and pebbles. Pure visuals — no physics,
/// z-order below all gameplay. Swapped for real tiles at art time.
enum GroundDressing {

    static func build(in rect: CGRect) -> [SKNode] {
        var nodes: [SKNode] = []
        nodes.append(contentsOf: pathStrip(in: rect))
        nodes.append(contentsOf: scatter(in: rect))
        return nodes
    }

    /// Broken segments of lighter ground running bottom → top: the trail
    /// every adventurer before you walked.
    private static func pathStrip(in rect: CGRect) -> [SKNode] {
        var nodes: [SKNode] = []
        var y = rect.minY + 60
        while y < rect.maxY - 40 {
            let segment = SKShapeNode(rectOf: CGSize(width: .random(in: 90...130),
                                                     height: .random(in: 70...110)),
                                      cornerRadius: 30)
            segment.fillColor = SKColor(red: 0.16, green: 0.20, blue: 0.13, alpha: 1)
            segment.strokeColor = .clear
            segment.position = CGPoint(x: .random(in: -35...35), y: y)
            segment.zPosition = -90
            nodes.append(segment)
            y += .random(in: 90...140)
        }
        return nodes
    }

    private static func scatter(in rect: CGRect) -> [SKNode] {
        var nodes: [SKNode] = []
        let inset = rect.insetBy(dx: 40, dy: 40)

        // Grass tufts
        for _ in 0..<22 {
            let tuft = SKNode()
            let base = CGPoint(x: .random(in: inset.minX...inset.maxX),
                               y: .random(in: inset.minY...inset.maxY))
            for blade in 0..<3 {
                let path = CGMutablePath()
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: CGFloat(blade - 1) * 3, y: .random(in: 7...12)))
                let line = SKShapeNode(path: path)
                line.strokeColor = SKColor(red: 0.25, green: 0.42, blue: 0.2, alpha: 0.9)
                line.lineWidth = 1.5
                tuft.addChild(line)
            }
            tuft.position = base
            tuft.zPosition = -80
            nodes.append(tuft)
        }

        // Flowers
        for _ in 0..<8 {
            let flower = SKShapeNode(circleOfRadius: .random(in: 2.5...4))
            flower.fillColor = [SKColor(red: 1, green: 0.85, blue: 0.24, alpha: 1),
                                SKColor(red: 1, green: 0.54, blue: 0.4, alpha: 1),
                                SKColor(red: 0.85, green: 0.7, blue: 1, alpha: 1)].randomElement()!
            flower.strokeColor = .clear
            flower.position = CGPoint(x: .random(in: inset.minX...inset.maxX),
                                      y: .random(in: inset.minY...inset.maxY))
            flower.zPosition = -80
            nodes.append(flower)
        }

        // Pebbles
        for _ in 0..<10 {
            let pebble = SKShapeNode(ellipseOf: CGSize(width: .random(in: 6...12),
                                                       height: .random(in: 4...8)))
            pebble.fillColor = SKColor(white: 0.28, alpha: 1)
            pebble.strokeColor = .clear
            pebble.position = CGPoint(x: .random(in: inset.minX...inset.maxX),
                                      y: .random(in: inset.minY...inset.maxY))
            pebble.zPosition = -80
            nodes.append(pebble)
        }
        return nodes
    }
}
