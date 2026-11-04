import AppKit
import SwiftUI

/// `ClaudeBuddy --snapshot <dir>` writes PNGs of every pose and of the overlay, for checking the art.
@MainActor
enum Snapshot {
    /// True while rendering, so animated AppKit extras swap in their static SwiftUI stand-ins.
    static var isRendering = false

    static func render(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        isRendering = true
        let moods: [(Mood, Pose)] = [
            (.asleep, Pose(face: .sleep)),
            (.idle, Pose(face: .open(glance: false))),
            (.working, Pose(face: .open(glance: true))),
            (.done, Pose(face: .happy, left: .up)),
            (.needsYou, Pose(face: .alarmed, left: .up, right: .wave)),
        ]
        for scheme in [ColorScheme.light, .dark] {
            let sheet = HStack(spacing: 22) {
                ForEach(moods, id: \.0) { mood, pose in
                    VStack(spacing: 1) {
                        MascotSprite(frame: MascotFrame(mood: mood, pose: pose), badge: mood == .done || mood == .needsYou ? 1 : 0)
                        NameTag(mood: mood)
                    }
                }
            }
            .padding(24)
            .background(scheme == .light ? Color(hex: 0xF3F4F8) : Color(hex: 0x1E1F24))
            .environment(\.colorScheme, scheme)
            save(sheet, dir.appendingPathComponent("moods-\(scheme == .light ? "light" : "dark").png"),
                 appearance: NSAppearance(named: scheme == .light ? .aqua : .darkAqua))
        }

        let store = SessionStore()
        store.startDemo()
        for scheme in [ColorScheme.light, .dark] {
            let ui = BuddyUI()
            ui.announcing = true
            ui.nudgedAt = .distantPast
            let view = BuddyRoot(store: store, ui: ui, host: nil)
                .background(scheme == .light ? Color(hex: 0xE9ECF2) : Color(hex: 0x1E1F24))
                .environment(\.colorScheme, scheme)
            save(view, dir.appendingPathComponent("overlay-\(scheme == .light ? "light" : "dark").png"),
                 appearance: NSAppearance(named: scheme == .light ? .aqua : .darkAqua))
        }
        let icon = ZStack {
            RoundedRectangle(cornerRadius: 230, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFFF4F8), Color(hex: 0xE4ECFF)], startPoint: .top, endPoint: .bottom))
            PixelBuddy(pose: Pose(face: .happy, left: .up), palette: Mood.idle.palette, px: 26)
                .offset(y: -50)
        }
        .frame(width: 1024, height: 1024)
        save(icon, dir.appendingPathComponent("icon.png"), scale: 1)

        print("snapshots written to \(dir.path)")
    }

    private static func save<V: View>(_ view: V, _ url: URL, appearance: NSAppearance? = nil, scale: CGFloat = 2) {
        let draw = {
            let r = ImageRenderer(content: view)
            r.scale = scale
            guard let cg = r.cgImage else { return }
            let rep = NSBitmapImageRep(cgImage: cg)
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
        }
        if let appearance { appearance.performAsCurrentDrawingAppearance(draw) } else { draw() }
    }
}
