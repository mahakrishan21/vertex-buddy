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
    static let panel = CGSize(width: 300, height: 500)
    static let bubbleWidth: CGFloat = 268
    /// How far the middle of the buddy's head sits above the bottom edge of the panel.
    static let headAboveBottom: CGFloat = 93
    static let rowHeight: CGFloat = 40
    static let visibleRows = 5
}

struct BuddyRoot: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var ui: BuddyUI
    @ObservedObject var engine: BehaviorEngine
    weak var host: PanelHost?

    private var showBubble: Bool {
        ui.hovering || ui.pinnedOpen || (ui.announcing && !store.alerts.isEmpty)
    }

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            if showBubble {
                Bubble(store: store, ui: ui, engine: engine)
                    .hitRegion()
                    .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
            }
            MascotView(store: store, ui: ui, engine: engine, host: host)
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
    let engine: BehaviorEngine
    weak var host: PanelHost?
    @State private var dragging = false
    @State private var pressStart: NSPoint?

    var body: some View {
        LiveMascot(screen: engine.screen, badge: store.alerts.count)
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
            .contextMenu { BuddyMenu(store: store, ui: ui, engine: engine) }
    }

    private func tap() {
        engine.poke()
        if let next = store.alerts.sorted(by: { $0.kind == .blocked && $1.kind != .blocked }).first {
            Activator.focus(next.session)
            store.acknowledge(next)
        } else {
            ui.pinnedOpen.toggle()
        }
    }
}

/// The live buddy with its name tag. SwiftUI only redraws this when the mood, label or extras
/// change; the robot itself repaints on its own.
private struct LiveMascot: View {
    @ObservedObject var screen: FrameBox
    let badge: Int

    var body: some View {
        let s = screen.status
        VStack(spacing: 1) {
            if Snapshot.isRendering {
                // ImageRenderer cannot draw an AppKit view, so snapshots get the still version.
                MascotSprite(frame: screen.frame, badge: badge, look: screen.look)
            } else {
                LiveRobot(box: screen)
                    .frame(width: RobotArt.size.width, height: RobotArt.size.height)
                    .mascotExtras(s, badge: badge)
            }
            NameTag(mood: s.mood, label: s.label, name: screen.look.name)
        }
    }
}

/// One still frame of the buddy with its extras, for snapshots.
struct MascotSprite: View {
    let frame: MascotFrame
    let badge: Int
    var look = Look.cozy

    var body: some View {
        RobotCanvas(frame: frame, look: look)
            .mascotExtras(MascotStatus(mood: frame.mood, label: frame.label, fx: frame.fx, alert: frame.alert),
                          badge: badge)
    }
}

private extension View {
    /// The glow behind, the floating extras in front, and the count badge by the ear.
    func mascotExtras(_ s: MascotStatus, badge: Int) -> some View {
        background(MoodEffects(fx: s.fx, mood: s.mood, glow: s.alert, layer: .behind))
            .overlay(MoodEffects(fx: s.fx, mood: s.mood, glow: s.alert, layer: .front))
            .overlay(alignment: .topTrailing) {
                Badge(count: badge, color: s.mood.accent).offset(x: -22, y: RobotArt.headTop - 10)
            }
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
    @ObservedObject var engine: BehaviorEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 7)
            sessionsHeader
                .padding(.horizontal, 12).padding(.bottom, 5)
            TimelineView(.periodic(from: .now, by: 20)) { _ in
                sessionList
            }
            // 8 of breathing room, plus the 8 the tail takes at the bottom of the shape.
            .padding(.bottom, 16)
        }
        .frame(width: Layout.bubbleWidth)
        .background(BubbleShape().fill(Color(nsColor: .windowBackgroundColor)))
        .overlay(BubbleShape().stroke(Color.primary.opacity(0.12), lineWidth: 1))
        .compositingGroup()
        .shadow(color: .black.opacity(0.14), radius: 12, y: 4)
        .padding(.bottom, 4)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Circle().fill(engine.current.mood.accent).frame(width: 7, height: 7)
            Text(headline)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 4)
            if store.alerts.count > 1 {
                Button("Clear all") { store.acknowledgeAll() }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Text(engine.pinned == nil ? "AUTO" : "PINNED")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
        }
    }

    /// What the buddy is doing, and for which session when a session is the reason.
    private var headline: String {
        let who = store.focusSession.map { " · \($0.name)" } ?? ""
        switch engine.current {
        case .needsYou: return "Needs you" + who
        case .yourTurn: return "Your turn" + who
        default:
            let base = "\(Buddy.name) is \(engine.current.label)"
            return engine.pinned == nil && engine.current.mood == .working ? base + who : base
        }
    }

    private var sessionsHeader: some View {
        HStack {
            Text(store.sessions.count == 1 ? "1 SESSION" : "\(store.sessions.count) SESSIONS")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(summary)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var summary: String {
        let blocked = store.alerts.filter { $0.kind == .blocked }.count
        let done = store.alerts.count - blocked
        let busy = store.sessions.filter(\.isBusy).count
        let parts = [(blocked, "need you"), (done, "your turn"), (busy, "working")]
            .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)" }
        return parts.isEmpty && !store.sessions.isEmpty ? "all quiet" : parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var sessionList: some View {
        let rows = store.ordered
        if rows.isEmpty {
            Text("No Claude sessions running.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.bottom, 2)
        } else {
            let shown = min(rows.count, Layout.visibleRows)
            let list = VStack(spacing: 3) {
                ForEach(rows) { s in row(s) }
            }
            .padding(.horizontal, 6)
            // A sliver of the next row peeks out when there is more to scroll to.
            let height = CGFloat(shown) * (Layout.rowHeight + 3) - 3 + (rows.count > shown ? 16 : 0)
            if Snapshot.isRendering {
                // ImageRenderer cannot draw a scroll view.
                list.frame(height: height, alignment: .top).clipped()
            } else {
                ScrollView(.vertical, showsIndicators: rows.count > shown) { list }
                    .frame(height: height)
            }
        }
    }

    private func row(_ s: ClaudeSession) -> some View {
        let alert = store.alert(for: s)
        let color: Color = alert.map { $0.kind == .blocked ? Mood.needsYou.accent : Mood.done.accent }
            ?? (s.isBusy ? Mood.working.accent : Color.secondary.opacity(0.45))
        return SessionRow(dot: color, pulsing: s.isBusy, title: s.name,
                          detail: "\(store.activity(s)) · \(store.hostName(s))",
                          age: s.statusUpdatedAt,
                          ring: s.id == store.focusSession?.id ? color : nil,
                          onDismiss: alert.map { a in { store.acknowledge(a) } }) {
            Activator.focus(s)
            if let alert { store.acknowledge(alert) }
        }
        .help(s.cwd)
    }
}

struct SessionRow: View {
    let dot: Color
    var pulsing = false
    let title: String
    let detail: String
    let age: Date
    var ring: Color? = nil
    var onDismiss: (() -> Void)? = nil
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            StatusDot(color: dot, pulsing: pulsing)
                .id(pulsing)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1)
                Text(detail).font(.system(size: 10.5, design: .rounded)).foregroundStyle(.secondary).lineLimit(1)
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
        .padding(.horizontal, 8)
        .frame(height: Layout.rowHeight)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(ring ?? .clear, lineWidth: 1.5).padding(0.75))
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

/// A status dot that sends out a soft ring while its session is working.
struct StatusDot: View {
    let color: Color
    let pulsing: Bool
    @State private var out = false

    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8)
            .background(
                Circle().stroke(color, lineWidth: 1.5)
                    .scaleEffect(out ? 2.2 : 1)
                    .opacity(pulsing ? (out ? 0 : 0.8) : 0)
            )
            .onAppear {
                guard pulsing, !Snapshot.isRendering else { return }
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) { out = true }
            }
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
    @ObservedObject var engine: BehaviorEngine

    var body: some View {
        if store.sessions.isEmpty {
            Text("No Claude sessions")
        } else {
            ForEach(store.ordered) { s in
                Button("\(s.isBlocked ? "●" : s.isBusy ? "◐" : "○")  \(s.name)") { Activator.focus(s) }
            }
        }
        Divider()
        if !store.alerts.isEmpty {
            Button("Dismiss all") { store.acknowledgeAll() }
        }
        // Choosing the pet and what it does lives here, to keep the bubble small.
        Picker("Pet", selection: Binding(get: { engine.screen.look }, set: { engine.screen.look = $0 })) {
            ForEach(Look.allCases) { look in
                Text(look.name).tag(look)
            }
        }
        Picker("Behaviour", selection: $engine.pinned) {
            Text("Auto (follows your sessions)").tag(Behavior?.none)
            Divider()
            ForEach(Behavior.pickable) { b in
                Text(b.title).tag(Behavior?.some(b))
            }
        }
        Toggle("Stroll when idle", isOn: $engine.strollWhenIdle)
        Divider()
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
