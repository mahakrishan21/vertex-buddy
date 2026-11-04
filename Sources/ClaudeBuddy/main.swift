import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = SessionStore()
    let ui = BuddyUI()
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

        overlay = OverlayController(store: store, ui: ui)
        if args.contains("--demo") { store.startDemo() } else { store.start() }
        overlay?.show()
    }
}

setvbuf(stdout, nil, _IOLBF, 0)
let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
