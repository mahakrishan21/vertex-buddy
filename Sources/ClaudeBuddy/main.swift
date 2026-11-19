import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = SessionStore()
    let ui = BuddyUI()
    var engine: BehaviorEngine?
    var overlay: OverlayController?

    func applicationDidFinishLaunching(_ note: Notification) {
        let args = CommandLine.arguments

        if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
            Snapshot.render(to: URL(fileURLWithPath: args[i + 1]))
            NSApp.terminate(nil)
            return
        }

        if args.contains("--status") {
            store.scan(quiet: true)
            print(store.report)
            NSApp.terminate(nil)
            return
        }

        // One buddy is plenty.
        if let bid = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bid).count > 1 {
            NSApp.terminate(nil)
            return
        }

        let engine = BehaviorEngine(store: store, ui: ui)
        // `--behavior walking` starts pinned to one behaviour, without changing the saved choice.
        if let i = args.firstIndex(of: "--behavior"), i + 1 < args.count {
            engine.remember = false
            engine.pinned = Behavior.pickable.first { $0.rawValue == args[i + 1] }
        }
        self.engine = engine
        overlay = OverlayController(store: store, ui: ui, engine: engine)
        if args.contains("--demo") { store.startDemo() } else { store.start() }
        engine.start()
        overlay?.show()
        // `--look cloud` shows one character for this run, without changing the saved choice.
        if let i = args.firstIndex(of: "--look"), i + 1 < args.count, let look = Look(rawValue: args[i + 1]) {
            DispatchQueue.main.async {
                engine.screen.remember = false
                engine.screen.look = look
            }
        }
    }
}

setvbuf(stdout, nil, _IOLBF, 0)
let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
