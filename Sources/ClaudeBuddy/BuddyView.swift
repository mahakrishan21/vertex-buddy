import ServiceManagement
import SwiftUI

/// UI-only state shared between the SwiftUI views and the panel controller.
@MainActor
final class BuddyUI: ObservableObject {
    @Published var hovering = false
    @Published var pinnedOpen = false
    @Published var announcing = false
    @Published var nudgedAt = Date.distantPast
    private var hideAnnouncement: DispatchWorkItem?

    /// Pop the bubble open for a while after something new happens, then fold back to the badge.
    func announce(for seconds: TimeInterval = 15) {
        nudgedAt = Date()
        announcing = true
        hideAnnouncement?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.announcing = false }
        hideAnnouncement = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }
}

/// What the overlay needs from the window that hosts it.
@MainActor
protocol PanelHost: AnyObject {
    func dragChanged()
    func dragEnded()
    func setHitRegions(_ rects: [CGRect])
}

struct HitRegionKey: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) { value += nextValue() }
}

extension View {
    /// Marks this view as clickable; everything else in the panel lets clicks fall through.
    func hitRegion() -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: HitRegionKey.self, value: [g.frame(in: .named("panel"))])
        })
    }
}

enum Layout {
    static let panel = CGSize(width: 270, height: 260)
    static let px: CGFloat = 3
}

struct BuddyRoot: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var ui: BuddyUI
    weak var host: PanelHost?

    private var showBubble: Bool {
        ui.hovering || ui.pinnedOpen || (ui.announcing && !store.alerts.isEmpty)
    }

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            if showBubble {
                Bubble(store: store, ui: ui)
                    .hitRegion()
                    .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
            }
            MascotView(store: store, ui: ui, host: host)
                .hitRegion()
        }
        .padding(.bottom, 4)
        .frame(width: Layout.panel.width, height: Layout.panel.height, alignment: .bottom)
        .coordinateSpace(name: "panel")
        .onPreferenceChange(HitRegionKey.self) { rects in
            MainActor.assumeIsolated { host?.setHitRegions(rects) }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: showBubble)
        .onChange(of: store.nudge) { ui.announce() }
    }
}

// MARK: - Mascot

struct MascotView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var ui: BuddyUI
    weak var host: PanelHost?
    @StateObject private var clock = MascotClock()
    @State private var dragging = false
    @State private var pressStart: NSPoint?

    var body: some View {
        let frame = clock.frame
            ?? MascotFrame.make(t: Date().timeIntervalSinceReferenceDate, store: store, nudgedAt: ui.nudgedAt)
        VStack(spacing: 1) {
            MascotSprite(frame: frame, badge: store.alerts.count)
                .equatable()
            NameTag(mood: frame.mood)
                .equatable()
        }
        .onAppear { clock.start(store: store, ui: ui) }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { _ in
                    let m = NSEvent.mouseLocation
                    if pressStart == nil { pressStart = m }
                    if let s = pressStart, !dragging, hypot(m.x - s.x, m.y - s.y) > 3 { dragging = true }
                    if dragging { host?.dragChanged() }
                }
                .onEnded { _ in
                    if dragging { host?.dragEnded() } else { tap() }
                    dragging = false
                    pressStart = nil
                }
        )
        .contextMenu { BuddyMenu(store: store, ui: ui) }
    }

    private func tap() {
        if let next = store.alerts.sorted(by: { $0.kind == .blocked && $1.kind != .blocked }).first {
            Activator.focus(next.session)
            store.acknowledge(next)
        } else {
            ui.pinnedOpen.toggle()
        }
    }
}

/// Works out the buddy's frame 12×/s but only publishes when it changes, so SwiftUI does no work
/// at all between changes; calm states move in whole sprite pixels and change a few times a second.
@MainActor
final class MascotClock: ObservableObject {
    @Published private(set) var frame: MascotFrame?
    private var timer: Timer?

    func start(store: SessionStore, ui: BuddyUI) {
        guard timer == nil else { return }
        let tick = { [weak self, weak store, weak ui] in
            guard let self, let store, let ui else { return }
            let next = MascotFrame.make(t: Date().timeIntervalSinceReferenceDate, store: store, nudgedAt: ui.nudgedAt)
            if next != self.frame { self.frame = next }
        }
        tick()
        let t = Timer(timeInterval: 1.0 / 12, repeats: true) { _ in MainActor.assumeIsolated { tick() } }
        t.tolerance = 0.01
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

/// One drawn frame of the buddy: cached sprite bitmap in its mood colour, the smooth extras,
/// ground shadow and count badge. A mood change cross-fades the colour.
struct MascotSprite: View, Equatable {
    let frame: MascotFrame
    let badge: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(RadialGradient(colors: [.black.opacity(0.16), .black.opacity(0)], center: .center,
                                     startRadius: 0, endRadius: 30))
                .frame(width: 60 - frame.lift * 1.4, height: 8)
            ZStack {
                Image(nsImage: SpriteCache.image(frame.pose, frame.mood))
                    .interpolation(.none)
                    .id(frame.mood)
                    .transition(.opacity)
            }
            .background(MoodEffects(mood: frame.mood, layer: .behind))
            .overlay(MoodEffects(mood: frame.mood, layer: .front))
            .scaleEffect(x: frame.squash, y: 2 - frame.squash, anchor: .bottom)
            .offset(y: -frame.lift - 3)
            .overlay(alignment: .topTrailing) {
                Badge(count: badge, color: frame.mood.accent).offset(x: -8, y: 12 - frame.lift)
            }
        }
        .frame(width: CGFloat(Sprite.width + Sprite.margin * 2) * Layout.px,
               height: CGFloat(Sprite.height + Sprite.headroom) * Layout.px + 6)
        .animation(.easeInOut(duration: 0.45), value: frame.mood)
    }
}

/// Renders each distinct pose once; after that a frame is just a bitmap swap.
@MainActor
enum SpriteCache {
    private static var images: [String: NSImage] = [:]

    static func image(_ pose: Pose, _ mood: Mood) -> NSImage {
        let key = "\(mood.rawValue)|\(pose)"
        if let hit = images[key] { return hit }
        let r = ImageRenderer(content: PixelBuddy(pose: pose, palette: mood.palette, px: Layout.px))
        r.scale = NSScreen.screens.map(\.backingScaleFactor).max() ?? 2
        let img = r.nsImage ?? NSImage()
        if images.count > 300 { images.removeAll() }
        images[key] = img
        return img
    }
}

/// Picks the buddy's pose and motion for a moment in time.
struct MascotFrame: Equatable {
    var mood = Mood.idle
    var pose = Pose()
    var lift: CGFloat = 0
    var squash: CGFloat = 1

    @MainActor
    static func make(t: Double, store: SessionStore, nudgedAt: Date) -> MascotFrame {
        var f = MascotFrame()
        f.mood = store.mood
        let blinking = t.truncatingRemainder(dividingBy: 4.3) < 0.2
        let sinceNudge = Date().timeIntervalSince(nudgedAt)
        let blocked = store.alerts.contains { $0.kind == .blocked }

        if !store.alerts.isEmpty {
            let wave = Int(t * (blocked ? 5 : 3)) % 2 == 0
            f.pose.face = blocked ? (blinking ? .blink : .alarmed) : .happy
            f.pose.left = wave ? .up : .wave
            f.pose.right = blocked ? (wave ? .wave : .up) : .down
            if sinceNudge < 1.8 {
                // Three soft hops that shrink, with a little squish on each landing.
                let phase = sinceNudge / 0.6
                let hop = abs(sin(phase * .pi))
                f.lift = (CGFloat(hop * 10 * (1 - sinceNudge / 1.8)) / 2).rounded() * 2
                f.squash = hop < 0.15 ? 1.06 : 1
            } else {
                f.lift = abs(sin(t * 2.5)) > 0.5 ? Layout.px : 0
            }
        } else if store.sessions.contains(where: \.isBusy) {
            f.pose.face = blinking ? .blink : .open(glance: true)
            f.lift = Int(t * 1.6) % 2 == 0 ? Layout.px : 0
        } else if store.sessions.isEmpty {
            f.pose.face = .sleep
            f.lift = Int(t * 0.8) % 2 == 0 ? Layout.px : 0
        } else {
            f.pose.face = blinking ? .blink : .open(glance: false)
            f.lift = Int(t * 1.1) % 2 == 0 ? Layout.px : 0
        }
        return f
    }
}

struct Badge: View {
    let count: Int
    let color: Color

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 17, minHeight: 17)
                .background(Circle().fill(color))
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        }
    }
}

// MARK: - Bubble

struct Bubble: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var ui: BuddyUI

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 12).padding(.top, 9).padding(.bottom, 5)
            TimelineView(.periodic(from: .now, by: 20)) { _ in
                VStack(spacing: 2) {
                    if store.alerts.isEmpty {
                        if store.sessions.isEmpty {
                            Text("No Claude sessions running.")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12).padding(.bottom, 4)
                        }
                        ForEach(store.sessions.prefix(5)) { s in
                            SessionRow(dot: dotColor(s), title: s.project, detail: statusText(s),
                                       age: s.statusUpdatedAt) { Activator.focus(s) }
                        }
                    } else {
                        ForEach(store.alerts.prefix(4)) { a in
                            SessionRow(dot: a.kind == .blocked ? Mood.needsYou.accent : Mood.done.accent,
                                       title: a.title, detail: a.detail, age: a.session.statusUpdatedAt,
                                       onDismiss: { store.acknowledge(a) }) {
                                Activator.focus(a.session)
                                store.acknowledge(a)
                            }
                        }
                        if store.alerts.count > 4 {
                            Text("+\(store.alerts.count - 4) more")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                                .padding(.leading, 12)
                        }
                    }
                }
                .padding(.horizontal, 4).padding(.bottom, 8)
            }
        }
        .frame(width: 226)
        .background(BubbleShape().fill(Color(nsColor: .windowBackgroundColor)))
        .overlay(BubbleShape().stroke(Color.primary.opacity(0.12), lineWidth: 1))
        .compositingGroup()
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.bottom, 4)
    }

    private var header: some View {
        HStack {
            Text(headline)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            if store.alerts.count > 1 {
                Button("Clear all") { store.acknowledgeAll() }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var headline: String {
        let n = store.alerts.count
        if n == 1 { return "1 session needs you" }
        if n > 1 { return "\(n) sessions need you" }
        let busy = store.sessions.filter(\.isBusy).count
        if busy > 0 { return busy == 1 ? "Claude is working…" : "\(busy) sessions working…" }
        return store.sessions.isEmpty ? "Sleeping… zzz" : "All quiet"
    }

    private func dotColor(_ s: ClaudeSession) -> Color {
        s.isBlocked ? Mood.needsYou.accent : s.isBusy ? Mood.working.accent : Mood.idle.accent.opacity(0.6)
    }

    private func statusText(_ s: ClaudeSession) -> String {
        if s.isBlocked { return "Needs your answer" }
        return s.isBusy ? "Working…" : "Idle"
    }
}

struct SessionRow: View {
    let dot: Color
    let title: String
    let detail: String
    let age: Date
    var onDismiss: (() -> Void)? = nil
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Circle().fill(dot).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1)
                Text(detail).font(.system(size: 10.5, design: .rounded)).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 4)
            Text(Self.ago(age)).font(.system(size: 10).monospacedDigit()).foregroundStyle(.tertiary)
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.04)))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    static func ago(_ d: Date) -> String {
        let s = max(0, Date().timeIntervalSince(d))
        if s < 60 { return "now" }
        if s < 3600 { return "\(Int(s / 60))m" }
        if s < 86400 { return "\(Int(s / 3600))h" }
        return "\(Int(s / 86400))d"
    }
}

/// Rounded card with a small tail pointing down at the buddy.
struct BubbleShape: Shape {
    func path(in r: CGRect) -> Path {
        let tail: CGFloat = 8
        let body = CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - tail)
        var p = Path(roundedRect: body, cornerRadius: 18, style: .continuous)
        p.move(to: CGPoint(x: r.midX - 9, y: body.maxY - 0.5))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX + 9, y: body.maxY - 0.5))
        p.closeSubpath()
        return p
    }
}

// MARK: - Menu

struct BuddyMenu: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var ui: BuddyUI

    var body: some View {
        if store.sessions.isEmpty {
            Text("No Claude sessions")
        } else {
            ForEach(store.sessions) { s in
                Button("\(s.isBlocked ? "●" : s.isBusy ? "◐" : "○")  \(s.project)") { Activator.focus(s) }
            }
        }
        Divider()
        if !store.alerts.isEmpty {
            Button("Dismiss all") { store.acknowledgeAll() }
        }
        Toggle("Sound", isOn: $store.soundOn)
        Picker("Remind me", selection: $store.remindEvery) {
            Text("Off").tag(0.0)
            Text("Every 2 min").tag(120.0)
            Text("Every 5 min").tag(300.0)
            Text("Every 10 min").tag(600.0)
        }
        Toggle("Open at login", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { on in try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }
        ))
        Divider()
        Button("Quit \(Buddy.name)") { NSApp.terminate(nil) }
    }
}
