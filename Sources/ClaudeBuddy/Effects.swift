import AppKit
import QuartzCore
import SwiftUI

enum Buddy {
    static let name = "Vertex"
}

/// The smooth extras around the buddy: progress dots while working, thought dots, drifting z's,
/// music notes, a "?", a passing firefly, and a soft glow when a session needs you. They run as
/// Core Animation layers, which the window server animates on its own, so they cost the app
/// nothing between changes.
struct MoodEffects: View {
    enum Layer { case behind, front }
    let fx: Fx
    let mood: Mood
    /// Only a waiting session lights the glow; a behaviour picked by hand never does.
    let glow: Bool
    let layer: Layer

    var body: some View {
        if Snapshot.isRendering {
            StaticMoodEffects(fx: fx, mood: mood, glow: glow, layer: layer)
        } else {
            AnimatedMoodEffects(fx: fx, mood: mood, glow: glow, layer: layer).allowsHitTesting(false)
        }
    }
}

/// Where the extras sit, in the buddy's drawing box (top-left origin).
private enum Spot {
    static let cx = RobotArt.center
    static let top = RobotArt.headTop
    static let dots: [CGPoint] = [-9, 0, 9].map { CGPoint(x: cx + $0, y: top - 15) }
    static let dot: CGFloat = 5.5
    static let thought: [(CGPoint, CGFloat)] = [(CGPoint(x: cx + 26, y: top - 12), 4.5),
                                                (CGPoint(x: cx + 35, y: top - 21), 7),
                                                (CGPoint(x: cx + 47, y: top - 31), 10.5)]
    static let zees: [(CGPoint, CGFloat)] = [(CGPoint(x: cx + 34, y: top + 10), 12), (CGPoint(x: cx + 45, y: top), 9)]
    static let notes: [(String, CGPoint, CGFloat)] = [("♪", CGPoint(x: cx - 57, y: top + 6), 13),
                                                      ("✦", CGPoint(x: cx + 60, y: top - 2), 10),
                                                      ("♫", CGPoint(x: cx + 59, y: top + 20), 13),
                                                      ("✦", CGPoint(x: cx - 60, y: top + 26), 9)]
    static let question = CGPoint(x: cx + 40, y: top - 16)
    static let glowCenter = CGPoint(x: cx, y: top + 34)
    static let glowSize = CGSize(width: 200, height: 160)
    static let fireflyColor = Color(hex: 0xC8EE3A)
}

private struct AnimatedMoodEffects: NSViewRepresentable {
    let fx: Fx
    let mood: Mood
    let glow: Bool
    let layer: MoodEffects.Layer

    func makeNSView(context: Context) -> EffectsView { EffectsView(front: layer == .front) }
    func updateNSView(_ v: EffectsView, context: Context) { v.apply(fx, mood, glow: glow) }
}

final class EffectsView: NSView {
    private let front: Bool
    private var showing: (Fx, Mood, Bool)?
    private let root = CALayer()

    init(front: Bool) {
        self.front = front
        super.init(frame: .zero)
        root.isGeometryFlipped = true
        layer = root
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func apply(_ fx: Fx, _ m: Mood, glow: Bool) {
        // The glow behind only depends on the mood; the extras in front on both.
        let key = front ? (fx, m, false) : (Fx.none, m, glow)
        if let showing, showing == key { return }
        showing = key
        root.sublayers?.forEach { $0.removeFromSuperlayer() }
        let accent = NSColor(m.accent).cgColor
        guard front else {
            guard glow else { return }
            if m == .done { addGlow(accent, period: 1.6, peak: 0.75) }
            if m == .needsYou { addGlow(accent, period: 0.8, peak: 1) }
            return
        }
        switch fx {
        case .none: break
        case .dots: addDots(accent)
        case .thought: addThought(accent)
        case .zees: addZees(accent)
        case .notes: addNotes(accent)
        case .question: addQuestion(accent)
        case .firefly(_, let leftToRight): addFirefly(leftToRight)
        }
    }

    private var scale: CGFloat { window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2 }

    private func text(_ s: String, size: CGFloat, color: CGColor, at p: CGPoint) -> CATextLayer {
        let t = CATextLayer()
        t.string = s
        let base = NSFont.systemFont(ofSize: size, weight: .heavy)
        t.font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
        t.fontSize = size
        t.foregroundColor = color
        t.alignmentMode = .center
        t.contentsScale = scale
        t.bounds = CGRect(x: 0, y: 0, width: size * 1.4, height: size * 1.3)
        t.position = p
        return t
    }

    private func addDots(_ color: CGColor) {
        let now = CACurrentMediaTime()
        for (i, p) in Spot.dots.enumerated() {
            let d = CALayer()
            d.bounds = CGRect(x: 0, y: 0, width: Spot.dot, height: Spot.dot)
            d.cornerRadius = Spot.dot / 2
            d.backgroundColor = color
            d.position = p
            d.opacity = 0.35

            let hop = CABasicAnimation(keyPath: "transform.translation.y")
            hop.fromValue = 0
            hop.toValue = -4
            let glow = CABasicAnimation(keyPath: "opacity")
            glow.fromValue = 0.35
            glow.toValue = 1
            let g = CAAnimationGroup()
            g.animations = [hop, glow]
            g.duration = 0.42
            g.autoreverses = true
            g.repeatCount = .infinity
            g.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            g.beginTime = now + Double(i) * 0.14
            g.fillMode = .backwards
            d.add(g, forKey: "think")
            root.addSublayer(d)
        }
    }

    /// Three dots that grow out of the head one after another, like a thought bubble forming.
    private func addThought(_ color: CGColor) {
        for (i, (p, size)) in Spot.thought.enumerated() {
            let d = CALayer()
            d.bounds = CGRect(x: 0, y: 0, width: size, height: size)
            d.cornerRadius = size / 2
            d.backgroundColor = color
            d.position = p
            d.opacity = 0

            let start = 0.08 + Double(i) * 0.16
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 0, 0.95, 0.95, 0]
            fade.keyTimes = [0, NSNumber(value: start), NSNumber(value: start + 0.1), 0.82, 1]
            let grow = CAKeyframeAnimation(keyPath: "transform.scale")
            grow.values = [0.3, 0.3, 1.15, 1, 1]
            grow.keyTimes = [0, NSNumber(value: start), NSNumber(value: start + 0.1), NSNumber(value: start + 0.18), 1]
            let g = CAAnimationGroup()
            g.animations = [fade, grow]
            g.duration = 2.6
            g.repeatCount = .infinity
            d.add(g, forKey: "thought")
            root.addSublayer(d)
        }
    }

    private func addZees(_ color: CGColor) {
        let now = CACurrentMediaTime()
        for (i, (p, size)) in Spot.zees.enumerated() {
            let t = text("z", size: size, color: color, at: p)
            t.opacity = 0

            let rise = CABasicAnimation(keyPath: "transform.translation")
            rise.fromValue = NSValue(size: .zero)
            rise.toValue = NSValue(size: CGSize(width: 5, height: -9))
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 0.9, 0.9, 0]
            fade.keyTimes = [0, 0.25, 0.7, 1]
            let g = CAAnimationGroup()
            g.animations = [rise, fade]
            g.duration = 2.6
            g.repeatCount = .infinity
            g.beginTime = now + Double(i) * 1.3
            g.fillMode = .backwards
            t.add(g, forKey: "drift")
            root.addSublayer(t)
        }
    }

    /// Music notes and sparkles that float up either side of the head.
    private func addNotes(_ color: CGColor) {
        let now = CACurrentMediaTime()
        for (i, (glyph, p, size)) in Spot.notes.enumerated() {
            let t = text(glyph, size: size, color: color, at: p)
            t.opacity = 0

            let out: CGFloat = p.x < Spot.cx ? -1 : 1
            let rise = CAKeyframeAnimation(keyPath: "transform.translation")
            rise.values = [CGSize.zero, CGSize(width: out * 5, height: -8), CGSize(width: out * 2, height: -17)]
                .map { NSValue(size: $0) }
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 1, 1, 0]
            fade.keyTimes = [0, 0.2, 0.65, 1]
            let g = CAAnimationGroup()
            g.animations = [rise, fade]
            g.duration = 1.9
            g.repeatCount = .infinity
            g.beginTime = now + Double(i) * 0.48
            g.fillMode = .backwards
            t.add(g, forKey: "float")
            root.addSublayer(t)
        }
    }

    /// A "?" that pops up once and fades.
    private func addQuestion(_ color: CGColor) {
        let t = text("?", size: 16, color: color, at: Spot.question)
        t.opacity = 0
        let pop = CAKeyframeAnimation(keyPath: "transform.scale")
        pop.values = [0.2, 1.3, 1, 1, 0.85]
        pop.keyTimes = [0, 0.14, 0.26, 0.8, 1]
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 1, 0]
        fade.keyTimes = [0, 0.12, 0.8, 1]
        let g = CAAnimationGroup()
        g.animations = [pop, fade]
        g.duration = 1.8
        t.add(g, forKey: "ask")
        root.addSublayer(t)
    }

    /// A small glowing dot that crosses above the buddy once, along `Firefly.point`.
    private func addFirefly(_ leftToRight: Bool) {
        let color = NSColor(Spot.fireflyColor).cgColor
        let d = CALayer()
        d.bounds = CGRect(x: 0, y: 0, width: 4, height: 4)
        d.cornerRadius = 2
        d.backgroundColor = color
        d.shadowColor = color
        d.shadowRadius = 4
        d.shadowOpacity = 1
        d.shadowOffset = .zero
        d.position = Firefly.point(0, leftToRight: leftToRight)
        d.opacity = 0

        let steps = 40
        let fly = CAKeyframeAnimation(keyPath: "position")
        fly.values = (0...steps).map { NSValue(point: Firefly.point(CGFloat($0) / CGFloat(steps), leftToRight: leftToRight)) }
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 0.5, 1, 0.6, 1, 0]
        fade.keyTimes = [0, 0.1, 0.3, 0.45, 0.65, 0.88, 1]
        let g = CAAnimationGroup()
        g.animations = [fly, fade]
        g.duration = Firefly.duration
        d.add(g, forKey: "fly")
        root.addSublayer(d)
    }

    private func addGlow(_ color: CGColor, period: Double, peak: Float) {
        let g = CAGradientLayer()
        g.type = .radial
        g.colors = [color.copy(alpha: 0.55)!, color.copy(alpha: 0)!]
        g.startPoint = CGPoint(x: 0.5, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 1)
        g.bounds = CGRect(origin: .zero, size: Spot.glowSize)
        g.position = Spot.glowCenter
        g.opacity = peak * 0.4

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = peak * 0.4
        pulse.toValue = peak
        pulse.duration = period
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        g.add(pulse, forKey: "pulse")
        root.addSublayer(g)
    }
}

/// Same extras frozen mid-motion, for `--snapshot` (ImageRenderer can't draw AppKit layers).
private struct StaticMoodEffects: View {
    let fx: Fx
    let mood: Mood
    let glow: Bool
    let layer: MoodEffects.Layer

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            if layer == .behind {
                if glow, mood == .done || mood == .needsYou {
                    Ellipse()
                        .fill(RadialGradient(colors: [mood.accent.opacity(0.4), mood.accent.opacity(0)], center: .center,
                                             startRadius: 0, endRadius: Spot.glowSize.width / 2))
                        .frame(width: Spot.glowSize.width, height: Spot.glowSize.height)
                        .position(Spot.glowCenter)
                }
            } else {
                front
            }
        }
    }

    @ViewBuilder
    private var front: some View {
        switch fx {
        case .none:
            EmptyView()
        case .dots:
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(mood.accent).opacity([1, 0.7, 0.4][i])
                    .frame(width: Spot.dot, height: Spot.dot)
                    .position(x: Spot.dots[i].x, y: Spot.dots[i].y - [3, 1.5, 0][i])
            }
        case .thought:
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(mood.accent)
                    .frame(width: Spot.thought[i].1, height: Spot.thought[i].1)
                    .position(Spot.thought[i].0)
            }
        case .zees:
            ForEach(0..<2, id: \.self) { i in
                Text("z").font(.system(size: Spot.zees[i].1, weight: .heavy, design: .rounded))
                    .foregroundStyle(mood.accent.opacity(0.9))
                    .position(Spot.zees[i].0)
            }
        case .notes:
            ForEach(0..<Spot.notes.count, id: \.self) { i in
                Text(Spot.notes[i].0).font(.system(size: Spot.notes[i].2, weight: .heavy, design: .rounded))
                    .foregroundStyle(mood.accent)
                    .position(x: Spot.notes[i].1.x, y: Spot.notes[i].1.y - CGFloat(i) * 3)
            }
        case .question:
            Text("?").font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(mood.accent)
                .position(Spot.question)
        case .firefly(_, let leftToRight):
            Circle().fill(Spot.fireflyColor)
                .frame(width: 4, height: 4)
                .shadow(color: Spot.fireflyColor, radius: 3)
                .position(Firefly.point(0.62, leftToRight: leftToRight))
        }
    }
}

/// A soft name tag under the buddy: a status dot in the mood colour, the name, and what it's doing.
struct NameTag: View, Equatable {
    let mood: Mood
    let label: String
    var name = Buddy.name

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(mood.accent).frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.85))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(Capsule().fill(Color(nsColor: .windowBackgroundColor).opacity(0.94)))
        .overlay(Capsule().stroke(mood.accent.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        .animation(.easeInOut(duration: 0.3), value: mood)
    }
}
