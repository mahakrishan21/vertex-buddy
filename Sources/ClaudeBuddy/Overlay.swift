import AppKit
import Combine
import SwiftUI

/// A borderless panel that floats above every app and every Space, including full-screen ones,
/// without ever taking keyboard focus away from what you are typing in.
final class OverlayPanel: NSPanel {
    init(size: CGSize) {
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Lets the first click land even though the panel never becomes key.
final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class OverlayController: PanelHost {
    let panel = OverlayPanel(size: Layout.panel)
    let store: SessionStore
    let ui: BuddyUI
    let engine: BehaviorEngine

    /// Where you parked the buddy. It strolls a little either side of this and always comes back.
    private var home = CGPoint.zero
    private var walkOffset: CGFloat = 0
    private var regions: [CGRect] = []
    private var mouseTimer: Timer?
    private var dragOffset: CGPoint?
    private var hoverWork: DispatchWorkItem?
    private var bag: Set<AnyCancellable> = []

    init(store: SessionStore, ui: BuddyUI, engine: BehaviorEngine) {
        self.store = store
        self.ui = ui
        self.engine = engine
        panel.contentView = FirstClickHostingView(rootView: BuddyRoot(store: store, ui: ui, engine: engine, host: self))
        panel.ignoresMouseEvents = true
        restorePosition()

        engine.onWalk = { [weak self] x in
            guard let self, self.dragOffset == nil else { return }
            self.walkOffset = x
            self.panel.setFrameOrigin(NSPoint(x: self.home.x + x, y: self.home.y))
        }
        engine.headCenter = { [weak self] in
            guard let f = self?.panel.frame else { return nil }
            return CGPoint(x: f.midX, y: f.minY + Layout.headAboveBottom)
        }

        // Polling the cursor 10×/s is far cheaper than a global monitor, which wakes us on every
        // mouse movement anywhere on screen.
        let poll = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.trackMouse() }
        }
        poll.tolerance = 0.03
        RunLoop.main.add(poll, forMode: .common)
        mouseTimer = poll

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.keepOnScreen() } }
            .store(in: &bag)
    }

    func show() { panel.orderFrontRegardless() }

    // MARK: PanelHost

    func setHitRegions(_ rects: [CGRect]) {
        regions = rects
        trackMouse()
    }

    func dragChanged() {
        let m = NSEvent.mouseLocation
        if dragOffset == nil {
            dragOffset = CGPoint(x: m.x - panel.frame.minX, y: m.y - panel.frame.minY)
            // Picked up mid-stroll: wherever it is put down becomes home.
            walkOffset = 0
            engine.resetWalk()
            engine.setHeld(true)
        }
        guard let o = dragOffset else { return }
        home = CGPoint(x: m.x - o.x, y: m.y - o.y)
        panel.setFrameOrigin(home)
    }

    func dragEnded() {
        dragOffset = nil
        engine.setHeld(false)
        keepOnScreen()
        UserDefaults.standard.set(NSStringFromPoint(home), forKey: "origin")
    }

    // MARK: Click-through + hover

    /// Only the buddy, its pill and its bubble catch the mouse; the rest of the panel is see-through.
    private func trackMouse() {
        guard dragOffset == nil else { return }
        let m = NSEvent.mouseLocation
        let f = panel.frame
        let p = CGPoint(x: m.x - f.minX, y: f.maxY - m.y)
        let inside = regions.contains { $0.insetBy(dx: -3, dy: -3).contains(p) }
        if panel.ignoresMouseEvents == inside { panel.ignoresMouseEvents = !inside }

        if inside, !ui.hovering, hoverWork == nil {
            let work = DispatchWorkItem { [weak self] in
                self?.ui.hovering = true
                self?.hoverWork = nil
            }
            hoverWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        } else if !inside {
            hoverWork?.cancel()
            hoverWork = nil
            if ui.hovering { ui.hovering = false }
            if ui.pinnedOpen { ui.pinnedOpen = false }
        }
    }

    // MARK: Position

    private func restorePosition() {
        if let saved = UserDefaults.standard.string(forKey: "origin") {
            home = NSPointFromString(saved)
        } else if let vf = NSScreen.main?.visibleFrame {
            home = CGPoint(x: vf.maxX - Layout.panel.width - 12, y: vf.minY + 12)
        }
        keepOnScreen()
    }

    /// Keeps the buddy itself (the bottom of the panel) on a visible screen, and tells it how far
    /// it may stroll either side of home without leaving that screen.
    private func keepOnScreen() {
        let size = panel.frame.size
        let buddy = CGRect(x: home.x + size.width / 2 - 60, y: home.y, width: 120, height: 170)
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(buddy) } ?? NSScreen.main
        guard let vf = screen?.visibleFrame else { return }
        let slack = (size.width - 120) / 2
        home.x = min(max(home.x, vf.minX - slack), vf.maxX - size.width + slack)
        home.y = min(max(home.y, vf.minY), vf.maxY - 170)

        let center = home.x + size.width / 2
        engine.walkRange = max(-110, min(0, vf.minX + 60 - center))...min(110, max(0, vf.maxX - 60 - center))
        walkOffset = min(max(walkOffset, engine.walkRange.lowerBound), engine.walkRange.upperBound)
        let origin = NSPoint(x: home.x + walkOffset, y: home.y)
        if origin != panel.frame.origin { panel.setFrameOrigin(origin) }
    }
}
