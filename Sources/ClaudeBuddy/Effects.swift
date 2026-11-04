import AppKit
import QuartzCore
import SwiftUI

enum Buddy {
    static let name = "Vertex"
}

/// The smooth, non-pixel extras around the buddy: bouncing dots while Claude works, drifting z's
/// while asleep, and a soft glow when a session needs you. They run as Core Animation layers,
/// which the window server animates on its own, so they cost the app nothing between mood changes.
struct MoodEffects: View {
    enum Layer { case behind, front }
    let mood: Mood
    let layer: Layer

    var body: some View {
        if Snapshot.isRendering {
            StaticMoodEffects(mood: mood, layer: layer)
        } else {
            AnimatedMoodEffects(mood: mood, layer: layer).allowsHitTesting(false)
        }
    }
}

/// Where the extras sit, in the sprite image's coordinates (top-left origin).
private enum Spot {
    static let dots: [CGPoint] = [CGPoint(x: 54, y: 11), CGPoint(x: 63, y: 11), CGPoint(x: 72, y: 11)]
    static let dot: CGFloat = 5.5
    static let zees: [(CGPoint, CGFloat)] = [(CGPoint(x: 66, y: 14), 11), (CGPoint(x: 76, y: 8), 8)]
    static let glowCenter = CGPoint(x: 45, y: 46)
    static let glowSize = CGSize(width: 128, height: 104)
}

private struct AnimatedMoodEffects: NSViewRepresentable {
    let mood: Mood
    let layer: MoodEffects.Layer

    func makeNSView(context: Context) -> EffectsView { EffectsView(front: layer == .front) }
    func updateNSView(_ v: EffectsView, context: Context) { v.apply(mood) }
}

final class EffectsView: NSView {
    private let front: Bool
    private var mood: Mood?
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

    func apply(_ m: Mood) {
        guard m != mood else { return }
        mood = m
        root.sublayers?.forEach { $0.removeFromSuperlayer() }
        let accent = NSColor(m.accent).cgColor
        switch (front, m) {
        case (true, .working): addDots(accent)
        case (true, .asleep): addZees(NSColor(m.palette.outline).cgColor)
        case (false, .done): addGlow(accent, period: 1.6, peak: 0.75)
        case (false, .needsYou): addGlow(accent, period: 0.8, peak: 1)
        default: break
        }
    }

    private var scale: CGFloat { window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2 }

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

    private func addZees(_ color: CGColor) {
        let now = CACurrentMediaTime()
        for (i, (p, size)) in Spot.zees.enumerated() {
            let t = CATextLayer()
            t.string = "z"
            let base = NSFont.systemFont(ofSize: size, weight: .heavy)
            t.font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
            t.fontSize = size
            t.foregroundColor = color
            t.alignmentMode = .center
            t.contentsScale = scale
            t.bounds = CGRect(x: 0, y: 0, width: size, height: size * 1.3)
            t.position = p
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
    let mood: Mood
    let layer: MoodEffects.Layer

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch (layer, mood) {
            case (.front, .working):
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(mood.accent).opacity([1, 0.7, 0.4][i])
                        .frame(width: Spot.dot, height: Spot.dot)
                        .position(x: Spot.dots[i].x, y: Spot.dots[i].y - [3, 1.5, 0][i])
                }
            case (.front, .asleep):
                ForEach(0..<2, id: \.self) { i in
                    Text("z").font(.system(size: Spot.zees[i].1, weight: .heavy, design: .rounded))
                        .foregroundStyle(mood.palette.outline.opacity(0.9))
                        .position(Spot.zees[i].0)
                }
            case (.behind, .done), (.behind, .needsYou):
                Ellipse()
                    .fill(RadialGradient(colors: [mood.accent.opacity(0.4), mood.accent.opacity(0)], center: .center,
                                         startRadius: 0, endRadius: Spot.glowSize.width / 2))
                    .frame(width: Spot.glowSize.width, height: Spot.glowSize.height)
                    .position(Spot.glowCenter)
            default:
                EmptyView()
            }
        }
    }
}

/// A soft name tag under the buddy: a status dot in the mood colour, the name, and what it's doing.
struct NameTag: View, Equatable {
    let mood: Mood

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(mood.accent).frame(width: 6, height: 6)
            Text(Buddy.name)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.85))
            Text(mood.label)
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
