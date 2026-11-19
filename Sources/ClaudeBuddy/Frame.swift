import SwiftUI

/// The box the buddy is drawn in, and where its parts sit, in points. The 3D model, the floating
/// extras and the engine all measure from these.
enum RobotArt {
    /// Head, legs, and room above for hops and extras.
    static let size = CGSize(width: 150, height: 136)
    static let center: CGFloat = 75
    /// The line the feet stand on, measured down from the top of the box.
    static let ground: CGFloat = 126
    /// Height of the neck, where the hood meets the hoodie, above the ground.
    static let legLength: CGFloat = 32
    static let headSize = CGSize(width: 86, height: 55)
    /// Where the top of the head sits when the buddy stands still.
    static let headTop: CGFloat = ground - legLength - headSize.height
}

/// The four characters Vertex can be. They share every behaviour and every expression; only the
/// body differs. Listed oldest first.
enum Look: String, CaseIterable, Identifiable {
    case cloud, pixel, robo, cozy
    var id: String { rawValue }

    /// The name shown under the buddy and in the menu.
    var name: String {
        switch self {
        case .cloud: return "Cloud Vertex"
        case .pixel: return "Pixel Vertex"
        case .robo: return "Robo Vertex"
        case .cozy: return "Cozy Vertex"
        }
    }

    /// The short name on the picker chip.
    var short: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    var about: String {
        switch self {
        case .cloud: return "The original little cloud, as a soft toy"
        case .pixel: return "The flat pixel-art robot"
        case .robo: return "The 3D robot with the boxy head"
        case .cozy: return "The one in the hoodie"
        }
    }
}

/// The colour Vertex glows in. It tells you the state from across the screen.
enum Mood: String, CaseIterable, Identifiable {
    case asleep, idle, working, done, needsYou
    var id: String { rawValue }

    var hex: UInt32 {
        switch self {
        case .asleep: return 0xA9A4F0
        case .idle: return 0x45D4E8
        case .working: return 0x48D97F
        case .done: return 0xFFC83D
        case .needsYou: return 0xFF5F87
        }
    }

    var accent: Color { Color(hex: hex) }
    var rgb: RGB { RGB(hex: hex) }

    /// The colour of the headphones, drawstrings and cuffs: Vertex's own neon green. They take
    /// the status colour only while a session is waiting for you.
    static let neon = RGB(hex: 0x39F06A)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

/// A plain colour that can be blended, so the glow can cross-fade between moods.
struct RGB: Equatable {
    var r, g, b: Double

    init(r: Double, g: Double, b: Double) { (self.r, self.g, self.b) = (r, g, b) }
    init(hex: UInt32) {
        self.init(r: Double((hex >> 16) & 0xFF) / 255, g: Double((hex >> 8) & 0xFF) / 255, b: Double(hex & 0xFF) / 255)
    }

    static let white = RGB(r: 1, g: 1, b: 1)

    func mixed(with o: RGB, _ t: Double) -> RGB {
        RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t)
    }

    func scaled(_ k: Double) -> RGB { RGB(r: r * k, g: g * k, b: b * k) }
    func ns(_ alpha: CGFloat = 1) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: alpha) }
}

/// One eye on the screen. `cut` lowers a flat lid from the top (0…1); `slant` tips the inner
/// corner down; `arc` turns the eye into a smiling arch (1) or a closed, gently curved line (-1).
struct Eye: Equatable {
    var w: CGFloat = 12
    var h: CGFloat = 8.5
    var cut: CGFloat = 0
    var slant: CGFloat = 0
    var arc: CGFloat = 0
}

/// One eyebrow: how far it is raised, and its tilt (positive tips the inner end down, a frown;
/// negative tips it up, a worried or gentle look).
struct Brow: Equatable {
    var lift: CGFloat = 0
    var angle: CGFloat = 0
}

/// One arm: how far it swings forward (negative is back) and how far it is raised out to the side,
/// in degrees. Hanging at rest is a raise of about 12; straight up overhead is 180.
struct Arm: Equatable {
    var swing: CGFloat = 0
    var raise: CGFloat = 12
}

/// How far a foot is off the ground and how far it has stepped sideways, in points.
struct Foot: Equatable {
    var lift: CGFloat = 0
    var dx: CGFloat = 0
}

/// The smooth extras floating around the buddy. The numbers restart a one-shot effect.
enum Fx: Equatable {
    case none, dots, thought, zees, notes
    case question(Int)
    case firefly(Int, leftToRight: Bool)
}

/// The path the firefly takes across the top of the buddy; its eyes follow the same curve.
enum Firefly {
    static let duration = 5.0

    static func point(_ p: CGFloat, leftToRight: Bool) -> CGPoint {
        let dir: CGFloat = leftToRight ? 1 : -1
        return CGPoint(x: RobotArt.center + dir * 88 * (2 * p - 1),
                       y: RobotArt.headTop - 12 - 12 * sin(p * .pi) + 5 * sin(p * 5 * .pi))
    }
}

/// Everything needed to draw the buddy at one instant.
struct MascotFrame: Equatable {
    var mood = Mood.idle
    var label = "idle"
    var accent = Mood.idle.rgb
    var trim = Mood.neon
    /// 1 is fully lit; lower dims the eyes and trim (asleep).
    var glow: CGFloat = 1
    var bodyX: CGFloat = 0
    /// How far the body has risen above standing height. Negative crouches.
    var bodyY: CGFloat = 0
    /// Head rolls to one side (degrees, clockwise), turns left or right, and nods up or down.
    var tilt: CGFloat = 0
    var yaw: CGFloat = 0
    var pitch: CGFloat = 0
    /// The whole body turns to face where it is walking (degrees, positive to the right).
    var turn: CGFloat = 0
    /// The whole body leans forward (degrees), as when running.
    var lean: CGFloat = 0
    var squash: CGFloat = 1
    var armL = Arm()
    var armR = Arm()
    var eyeL = Eye()
    var eyeR = Eye()
    var browL = Brow()
    var browR = Brow()
    /// How visible the eyebrows are. A plain, neutral face has none.
    var brows: CGFloat = 0
    /// Eye offset on the screen, in points.
    var gaze = CGPoint.zero
    var blush: CGFloat = 0
    var footL = Foot()
    var footR = Foot()
    var fx = Fx.none
    var held = false
    /// A session is waiting for you, so the buddy glows.
    var alert = false
}
