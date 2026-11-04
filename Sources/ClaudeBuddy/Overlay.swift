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

    private var regions: [CGRect] = []
    private var mouseTimer: Timer?
    private var dragOffset: CGPoint?
    private var hoverWork: DispatchWorkItem?
    private var bag: Set<AnyCancellable> = []

    init(store: SessionStore, ui: BuddyUI) {
        self.store = store
        self.ui = ui
        panel.contentView = FirstClickHostingView(rootView: BuddyRoot(store: store, ui: ui, host: self))
        panel.ignoresMouseEvents = true
        restorePosition()

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
        }
        guard let o = dragOffset else { return }
        panel.setFrameOrigin(NSPoint(x: m.x - o.x, y: m.y - o.y))
    }

    func dragEnded() {
        dragOffset = nil
        keepOnScreen()
        UserDefaults.standard.set(NSStringFromPoint(panel.frame.origin), forKey: "origin")
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
        if let s = UserDefaults.standard.string(forKey: "origin") {
            panel.setFrameOrigin(NSPointFromString(s))
        } else if let vf = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: vf.maxX - Layout.panel.width - 12, y: vf.minY + 12))
        }
        keepOnScreen()
    }

    /// Keeps the buddy itself (the bottom of the panel) on a visible screen.
    private func keepOnScreen() {
        let f = panel.frame
        let buddy = CGRect(x: f.midX - 60, y: f.minY, width: 120, height: 170)
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(buddy) } ?? NSScreen.main
        guard let vf = screen?.visibleFrame else { return }
        var o = f.origin
        o.x = min(max(o.x, vf.minX - (f.width - 120) / 2), vf.maxX - f.width + (f.width - 120) / 2)
        o.y = min(max(o.y, vf.minY), vf.maxY - 170)
        if o != f.origin { panel.setFrameOrigin(o) }
    }
}
