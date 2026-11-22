import AppKit
import SwiftUI

/// `ClaudeBuddy --film spec.json out/` writes the buddy as frame sequences with a transparent
/// background, drawn by the same model and the same engine as the live app. It is how footage for
/// videos is made: the same spec gives the same frames every run.
///
/// The spec is JSON:
///
///     { "takes":   [{ "name": "day", "look": "cozy", "scale": 4.8, "seed": 11, "preroll": 16,
///                     "duration": 26.4, "script": [[0, "sleeping"], [4.8, "idle"]], "pokes": [22.5],
///                     "holds": [[-1, 0.4]] }],
///       "bubbles": [{ "name": "done", "scale": 4, "scheme": "light",
///                     "before": [["website", "busy"]], "after": [["website", "idle"]] }] }
///
/// A session row is name, status, then optionally what it waits for, its entrypoint and how many
/// seconds it has been in that status.
///
/// A take plays its script from `preroll` seconds before zero, so the first behaviour has settled
/// when recording starts. Each take is written to `out/<name>/0000.png …` with a `take.json` that
/// says, frame by frame, which behaviour and which floating extra was showing.
@MainActor
enum Film {
    static let fps = 30.0

    static func render(spec url: URL, to dir: URL) {
        guard let data = try? Data(contentsOf: url),
              let spec = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("film: cannot read \(url.path)")
            return
        }
        Snapshot.isRendering = true
        for take in spec["takes"] as? [[String: Any]] ?? [] { record(take, to: dir) }
        for bubble in spec["bubbles"] as? [[String: Any]] ?? [] { bubbleImage(bubble, to: dir) }
        if let faces = spec["faces"] as? [String: Any] { faceImages(faces, to: dir) }
        print("film written to \(dir.path)")
    }

    private static func record(_ take: [String: Any], to dir: URL) {
        guard let name = take["name"] as? String, let duration = take["duration"] as? Double else { return }
        let look = (take["look"] as? String).flatMap(Look.init(rawValue:)) ?? .cozy
        let scale = CGFloat(take["scale"] as? Double ?? 4)
        let preroll = take["preroll"] as? Double ?? 0
        let script: [(Double, Behavior)] = (take["script"] as? [[Any]] ?? []).compactMap { row in
            guard row.count == 2, let t = (row[0] as? NSNumber)?.doubleValue,
                  let b = (row[1] as? String).flatMap(Behavior.init(rawValue:)) else { return nil }
            return (t, b)
        }
        var pokes = (take["pokes"] as? [NSNumber] ?? []).map(\.doubleValue).sorted()
        // "holds": [[from, to]] picks the buddy up for those seconds and drops it at the end of each.
        let holds = (take["holds"] as? [[NSNumber]] ?? []).filter { $0.count == 2 }.map { ($0[0].doubleValue, $0[1].doubleValue) }
        let out = dir.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: out)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let engine = BehaviorEngine(store: nil, ui: nil, seed: UInt64((take["seed"] as? NSNumber)?.intValue ?? 7))
        engine.headCenter = { .zero }
        engine.cursor = { CGPoint(x: 4000, y: 4000) }   // nobody is near: no hover reactions
        engine.strollWhenIdle = false
        var walkX: CGFloat = 0
        var walked: [Double] = []
        engine.onWalk = { walkX = $0 }

        let frames = Int((duration * fps).rounded())
        var track: [[String: Any]] = []
        var last = ""
        var t = -preroll
        var index = 0
        let step = 1.0 / fps
        while index < frames {
            engine.forced = script.last { $0.0 <= max(t, 0) + 1e-6 }?.1 ?? script.first?.1 ?? .idle
            if let p = pokes.first, t >= p - 1e-6 {
                engine.poke()
                pokes.removeFirst()
            }
            engine.setHeld(holds.contains { t >= $0.0 - 1e-6 && t < $0.1 - 1e-6 })
            engine.step(at: t + preroll)
            if t >= -1e-6 {
                walked.append(Double(walkX))
                let f = engine.screen.frame
                if let image = Robot3D.image(f, look: look, scale: scale) { write(image, out.appendingPathComponent(String(format: "%04d.png", index))) }
                let state = "\(engine.current.rawValue)|\(fxName(f.fx))|\(f.alert)"
                if state != last {
                    last = state
                    track.append(["frame": index, "t": Double(index) / fps, "behaviour": engine.current.rawValue,
                                  "fx": fxName(f.fx), "alert": f.alert, "mood": f.mood.rawValue])
                }
                index += 1
            }
            t += step
        }
        let size = ["w": Int(RobotArt.size.width * scale), "h": Int(RobotArt.size.height * scale)]
        // How far the buddy has strolled from its spot at each frame, in points: the app moves its window by this.
        let walk: [Double] = walked.contains { $0 != 0 } ? walked : []
        let meta: [String: Any] = ["name": name, "look": look.rawValue, "fps": fps, "frames": frames, "size": size, "walk": walk, "scale": Double(scale),
                                   "ground": Double(RobotArt.ground / RobotArt.size.height),
                                   "headTop": Double(RobotArt.headTop / RobotArt.size.height), "track": track]
        if let json = try? JSONSerialization.data(withJSONObject: meta, options: [.prettyPrinted, .sortedKeys]) {
            try? json.write(to: out.appendingPathComponent("take.json"))
        }
        print("film: \(name) \(frames) frames, \(size["w"]!) x \(size["h"]!)")
    }

    /// Every face on its own, standing still: `"faces": { "look": "cozy", "scale": 3 }` writes `out/faces/<name>.png`.
    private static func faceImages(_ spec: [String: Any], to dir: URL) {
        let look = (spec["look"] as? String).flatMap(Look.init(rawValue:)) ?? .cozy
        let scale = CGFloat(spec["scale"] as? Double ?? 3)
        let out = dir.appendingPathComponent("faces")
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let engine = BehaviorEngine(store: nil, ui: nil, seed: 1)
        for face in BehaviorEngine.Face.allCases {
            if let image = Robot3D.image(engine.still(face), look: look, scale: scale) {
                write(image, out.appendingPathComponent("\(face.rawValue).png"))
            }
        }
        print("film: faces \(BehaviorEngine.Face.allCases.count)")
    }

    private static func fxName(_ fx: Fx) -> String {
        switch fx {
        case .none: return "none"
        case .dots: return "dots"
        case .thought: return "thought"
        case .zees: return "zees"
        case .notes: return "notes"
        case .question: return "question"
        case .firefly: return "firefly"
        }
    }

    /// The speech bubble as the app draws it, with the given sessions, on a transparent ground.
    private static func bubbleImage(_ spec: [String: Any], to dir: URL) {
        guard let name = spec["name"] as? String else { return }
        let dark = spec["scheme"] as? String == "dark"
        func sessions(_ key: String) -> [ClaudeSession] {
            let now = Date()
            return (spec[key] as? [[String]] ?? []).enumerated().map { i, row in
                ClaudeSession(pid: 0, sessionId: row[0], name: row[0], cwd: "/tmp/\(row[0])", status: row[1],
                              waitingFor: row.count > 2 && !row[2].isEmpty ? row[2] : nil,
                              entrypoint: row.count > 3 ? row[3] : "claude-vscode",
                              startedAt: now.addingTimeInterval(Double(i) - 9000),
                              statusUpdatedAt: now.addingTimeInterval(-(row.count > 4 ? Double(row[4]) ?? 0 : 0)))
            }
        }
        let store = SessionStore()
        store.showFilm(sessions("before"), sessions("after"))
        let ui = BuddyUI()
        ui.announcing = true
        ui.nudgedAt = .distantPast
        let engine = BehaviorEngine(store: store, ui: ui, seed: 3)
        _ = engine.simulate(.idle, at: [0.5])
        engine.forced = nil
        engine.step(at: 0.6)
        let view = Bubble(store: store, ui: ui, engine: engine)
            .padding(24)
            .environment(\.colorScheme, dark ? .dark : .light)
        let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        appearance?.performAsCurrentDrawingAppearance {
            let r = ImageRenderer(content: view)
            r.scale = CGFloat(spec["scale"] as? Double ?? 4)
            r.isOpaque = false
            if let cg = r.cgImage {
                try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?
                    .write(to: dir.appendingPathComponent("bubble-\(name).png"))
                print("film: bubble-\(name) \(cg.width) x \(cg.height)")
            }
        }
    }

    private static func write(_ image: NSImage, _ url: URL) {
        var rect = CGRect(origin: .zero, size: image.size)
        guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return }
        try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?.write(to: url)
    }
}
