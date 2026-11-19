import AppKit
import SwiftUI

/// `ClaudeBuddy --snapshot <dir>` writes PNGs of every behaviour and of the overlay, for checking the art.
@MainActor
enum Snapshot {
    /// True while rendering, so animated AppKit extras swap in their static SwiftUI stand-ins.
    static var isRendering = false

    static func render(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        isRendering = true

        // One row per behaviour: five moments from a run of it, started from standing still.
        let times: [Behavior: [Double]] = [
            .sleeping: [0.8, 2.2, 4, 8, 14],
            .walking: [1.0, 1.4, 1.8, 2.6, 5],
            .watching: [1, 3, 5.5, 8, 11],
        ]
        let strips: [(Behavior, [MascotFrame])] = Behavior.allCases.map { b in
            let engine = BehaviorEngine(store: nil, ui: nil, seed: 7 + UInt64(b.rawValue.count))
            var clock = 0.0
            engine.headCenter = { .zero }
            engine.cursor = {
                clock += 1.0 / 30
                return CGPoint(x: 330 * cos(clock * 1.3), y: 120 + 200 * sin(clock * 0.9))
            }
            return (b, engine.simulate(b, at: times[b] ?? [0.7, 1.6, 2.7, 3.9, 5.2]))
        }

        for scheme in [ColorScheme.light, .dark] {
            let name = scheme == .light ? "light" : "dark"
            let appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)
            let sheet = VStack(alignment: .leading, spacing: 4) {
                ForEach(strips, id: \.0) { b, frames in
                    HStack(spacing: 10) {
                        NameTag(mood: b.mood, label: b.label)
                            .frame(width: 130, alignment: .leading)
                        ForEach(0..<frames.count, id: \.self) { i in
                            MascotSprite(frame: frames[i], badge: b.isAlert && i == 0 ? 1 : 0)
                        }
                    }
                }
            }
            .padding(24)
            .background(scheme == .light ? Color(hex: 0xF3F4F8) : Color(hex: 0x1E1F24))
            .environment(\.colorScheme, scheme)
            save(sheet, dir.appendingPathComponent("behaviors-\(name).png"), appearance: appearance)

            // The overlay as it looks with the bubble in use, and as it pops up for an alert.
            let store = SessionStore()
            store.startDemo(animated: false)
            for (file, open) in [("overlay", true), ("alert", false)] {
                let ui = BuddyUI()
                ui.pinnedOpen = open
                ui.announcing = true
                ui.nudgedAt = .distantPast
                let engine = BehaviorEngine(store: store, ui: ui, seed: 3)
                _ = engine.simulate(.needsYou, at: [1.0])
                engine.forced = nil
                engine.step(at: 1.1)
                let view = BuddyRoot(store: store, ui: ui, engine: engine, host: nil)
                    .background(scheme == .light ? Color(hex: 0xE9ECF2) : Color(hex: 0x1E1F24))
                    .environment(\.colorScheme, scheme)
                save(view, dir.appendingPathComponent("\(file)-\(name).png"), appearance: appearance)
            }
        }

        // All four characters in the same six moments, to check each one wears every pose.
        func moment(_ b: Behavior, _ i: Int) -> MascotFrame { strips.first { $0.0 == b }!.1[i] }
        let moments = [moment(.idle, 0), moment(.working, 0), moment(.walking, 2), moment(.sleeping, 3),
                       moment(.happy, 1), moment(.needsYou, 0)]
        for scheme in [ColorScheme.light, .dark] {
            let cast = VStack(alignment: .leading, spacing: 6) {
                ForEach(Look.allCases) { look in
                    HStack(spacing: 10) {
                        Text(look.name).font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(scheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.75))
                            .frame(width: 110, alignment: .leading)
                        ForEach(0..<moments.count, id: \.self) { i in
                            MascotSprite(frame: moments[i], badge: 0, look: look)
                        }
                    }
                }
            }
            .padding(24)
            .background(scheme == .light ? Color(hex: 0xF3F4F8) : Color(hex: 0x1E1F24))
            .environment(\.colorScheme, scheme)
            save(cast, dir.appendingPathComponent("characters-\(scheme == .light ? "light" : "dark").png"),
                 appearance: NSAppearance(named: scheme == .light ? .aqua : .darkAqua))
        }

        // Every face Vertex can pull, larger, on its own.
        let faceEngine = BehaviorEngine(store: nil, ui: nil, seed: 1)
        let faces = BehaviorEngine.Face.allCases.map { ($0.rawValue, faceEngine.still($0)) }
        let faceSheet = LazyVGrid(columns: Array(repeating: GridItem(.fixed(240), spacing: 8), count: 4), spacing: 4) {
            ForEach(faces, id: \.0) { name, frame in
                VStack(spacing: 0) {
                    RobotCanvas(frame: frame, scale: 1.6)
                    Text(name).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(24)
        .background(Color(hex: 0x1E1F24))
        save(faceSheet, dir.appendingPathComponent("faces.png"))

        var face = MascotFrame()
        face.eyeL.arc = 1
        face.eyeR.arc = 1
        face.browL = Brow(lift: 2, angle: -6)
        face.browR = Brow(lift: 2, angle: -6)
        face.brows = 0.85
        face.blush = 1
        face.tilt = -5
        face.yaw = 12
        let icon = ZStack {
            RoundedRectangle(cornerRadius: 230, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xE9FBFF), Color(hex: 0xC9D6FF)], startPoint: .top, endPoint: .bottom))
            RobotCanvas(frame: face, scale: 6.4)
                .offset(y: -55)
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
