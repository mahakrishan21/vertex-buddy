import SwiftUI

/// The buddy: a small, soft pixel cloud with shiny eyes and blushing cheeks.
/// Grid legend: o outline, b body, s shade.
enum Sprite {
    static let rows: [String] = [
        ".........oooooo.........",
        "....ooo.obbbbbbo.ooo....",
        "...obbbobbbbbbbbobbbo...",
        "..obbbbbbbbbbbbbbbbbbo..",
        ".obbbbbbbbbbbbbbbbbbbbo.",
        ".obbbbbbbbbbbbbbbbbbbbo.",
        "obbbbbbbbbbbbbbbbbbbbbbo",
        "obbbbbbbbbbbbbbbbbbbbbbo",
        "obbbbbbbbbbbbbbbbbbbbbbo",
        "obbbbbbbbbbbbbbbbbbbbbso",
        "obbbbbbbbbbbbbbbbbbbbbso",
        "obbbbbbbbbbbbbbbbbbbbbso",
        "obbbbbbbbbbbbbbbbbbbbbso",
        "osbbbbbbbbbbbbbbbbbbbbso",
        ".osbbbbbbbbbbbbbbbbbbso.",
        "..ossbbbbbbbbbbbbbbsso..",
        "...oossbbbssssbbbssoo...",
        ".....oosssoooosssoo.....",
        ".......ooo....ooo.......",
    ]

    static let width = 24
    static let height = rows.count
    /// Empty rows kept above the head for the z's and thinking dots drawn on top.
    static let headroom = 6
    /// Empty columns either side so the little arms can wave clear of the body.
    static let margin = 3

    static let grid: [[Character]] = rows.map(Array.init)

    typealias Px = (x: Int, y: Int)

    enum Face: Equatable { case open(glance: Bool), blink, happy, alarmed, sleep }
    enum Arm: Equatable { case down, up, wave }

    static let gloss: [Px] = [(4, 4), (5, 4), (4, 5), (3, 6)]
    static let cheeks: [Px] = [(5, 12), (6, 12), (17, 12), (18, 12)]

    /// Dark face pixels, plus the white glints that make the eyes shine.
    static func face(_ f: Face) -> (ink: [Px], glint: [Px]) {
        let eyes: [Px] = [(7, 9), (8, 9), (7, 10), (8, 10), (7, 11), (8, 11),
                          (15, 9), (16, 9), (15, 10), (16, 10), (15, 11), (16, 11)]
        let smile: [Px] = [(10, 12), (13, 12), (11, 13), (12, 13)]
        switch f {
        case .open(let glance):
            return (eyes + (glance ? [(11, 13), (12, 13)] : smile),
                    glance ? [(8, 9), (16, 9)] : [(7, 9), (15, 9)])
        case .blink:
            return ([(7, 11), (8, 11), (15, 11), (16, 11)] + smile, [])
        case .happy:
            return ([(6, 10), (7, 9), (8, 9), (9, 10), (14, 10), (15, 9), (16, 9), (17, 10)] + smile, [])
        case .alarmed:
            return (eyes + [(7, 8), (8, 8), (15, 8), (16, 8), (11, 12), (12, 12), (11, 13), (12, 13)],
                    [(7, 8), (15, 8)])
        case .sleep:
            return ([(6, 11), (7, 11), (8, 11), (15, 11), (16, 11), (17, 11), (11, 13), (12, 13)], [])
        }
    }

    /// Arm pixels for the buddy's left side; the right side is mirrored.
    static func leftArm(_ a: Arm) -> [Px] {
        switch a {
        case .down: return [(0, 11), (-1, 11), (0, 12), (-1, 12)]
        case .up:   return [(0, 9), (-1, 9), (-1, 8), (-2, 8), (-2, 7), (-1, 7)]
        case .wave: return [(0, 10), (-1, 10), (-2, 10), (-2, 9), (-3, 9), (-2, 8), (-3, 8)]
        }
    }

    static func mirror(_ p: [Px]) -> [Px] { p.map { (width - 1 - $0.x, $0.y) } }
}

struct BuddyPalette {
    let outline, body, shade, highlight, ink, cheek: Color
}

/// What the buddy is up to. Each mood has its own body colour, plus an accent for the smooth extras
/// (dots, glow, name tag) so you can read the state from across the screen.
enum Mood: String, CaseIterable, Identifiable {
    case asleep, idle, working, done, needsYou
    var id: String { rawValue }

    var label: String {
        switch self {
        case .asleep: return "sleeping"
        case .idle: return "idle"
        case .working: return "working"
        case .done: return "your turn"
        case .needsYou: return "needs you"
        }
    }

    var accent: Color {
        switch self {
        case .asleep: return Color(hex: 0xA5A1DE)
        case .idle: return Color(hex: 0x7F9CF5)
        case .working: return Color(hex: 0x34C26B)
        case .done: return Color(hex: 0xF5B82E)
        case .needsYou: return Color(hex: 0xFF5F87)
        }
    }

    var palette: BuddyPalette {
        switch self {
        case .asleep:
            return BuddyPalette(outline: Color(hex: 0x9A97C9), body: Color(hex: 0xEEEDFB), shade: Color(hex: 0xD9D7F2),
                                highlight: Color(hex: 0xFFFFFF), ink: Color(hex: 0x3A3866), cheek: Color(hex: 0xFFB8CB))
        case .idle:
            return BuddyPalette(outline: Color(hex: 0x5C6EC8), body: Color(hex: 0xB0C6FF), shade: Color(hex: 0x92AAF0),
                                highlight: Color(hex: 0xE2EBFF), ink: Color(hex: 0x282E60), cheek: Color(hex: 0xFF96B4))
        case .working:
            return BuddyPalette(outline: Color(hex: 0x3E9A5A), body: Color(hex: 0xB9EFC3), shade: Color(hex: 0x92DEA2),
                                highlight: Color(hex: 0xE8FCEB), ink: Color(hex: 0x1E4A2C), cheek: Color(hex: 0xFF9EB5))
        case .done:
            return BuddyPalette(outline: Color(hex: 0xC9962A), body: Color(hex: 0xFFE8A6), shade: Color(hex: 0xF8D37C),
                                highlight: Color(hex: 0xFFF7DC), ink: Color(hex: 0x4A3510), cheek: Color(hex: 0xFF9A8F))
        case .needsYou:
            return BuddyPalette(outline: Color(hex: 0xD05A78), body: Color(hex: 0xFFC4D1), shade: Color(hex: 0xF7A0B5),
                                highlight: Color(hex: 0xFFE8EE), ink: Color(hex: 0x5A1F2E), cheek: Color(hex: 0xFF7A98))
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

struct Pose: Equatable {
    var face: Sprite.Face = .open(glance: false)
    var left: Sprite.Arm = .down
    var right: Sprite.Arm = .down
}

/// Draws one frame of the buddy, pixel by pixel.
struct PixelBuddy: View {
    var pose: Pose
    var palette: BuddyPalette
    var px: CGFloat = 3

    var body: some View {
        Canvas { ctx, _ in
            let top = Sprite.headroom, left = Sprite.margin
            func fill(_ x: Int, _ y: Int, _ c: Color, size: CGFloat = 1) {
                ctx.fill(Path(CGRect(x: CGFloat(x + left) * px, y: CGFloat(y + top) * px,
                                     width: px * size, height: px * size)), with: .color(c))
            }
            let p = palette
            for (y, row) in Sprite.grid.enumerated() {
                for (x, ch) in row.enumerated() {
                    switch ch {
                    case "o": fill(x, y, p.outline)
                    case "b": fill(x, y, p.body)
                    case "s": fill(x, y, p.shade)
                    default: break
                    }
                }
            }
            for g in Sprite.gloss { fill(g.x, g.y, p.highlight) }

            // Arms sit in front of the body; each gets its own outline.
            for arm in [Sprite.leftArm(pose.left), Sprite.mirror(Sprite.leftArm(pose.right))] {
                let set = Set(arm.map { $0.y * 100 + $0.x })
                for a in arm {
                    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                        let nx = a.x + dx, ny = a.y + dy
                        guard !set.contains(ny * 100 + nx) else { continue }
                        let inGrid = ny >= 0 && ny < Sprite.height && nx >= 0 && nx < Sprite.width
                        let under: Character = inGrid ? Sprite.grid[ny][nx] : "."
                        if under == "." { fill(nx, ny, p.outline) }
                    }
                }
                for a in arm { fill(a.x, a.y, p.body) }
            }

            let face = Sprite.face(pose.face)
            for c in Sprite.cheeks { fill(c.x, c.y, p.cheek) }
            for f in face.ink { fill(f.x, f.y, p.ink) }
            for g in face.glint { fill(g.x, g.y, .white) }
        }
        .frame(width: CGFloat(Sprite.width + Sprite.margin * 2) * px, height: CGFloat(Sprite.height + Sprite.headroom) * px)
    }
}
