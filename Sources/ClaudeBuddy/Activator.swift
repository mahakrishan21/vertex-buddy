import AppKit

/// Brings the window that hosts a Claude session to the front.
enum Activator {
    /// VS Code-family editors focus the window that already has a folder open
    /// when asked to open that folder again, which lands you on the right project.
    private static let editors: Set<String> = [
        "com.microsoft.VSCode", "com.microsoft.VSCodeInsiders", "com.vscodium",
        "com.todesktop.230313mzl4w4u92", "com.exafunction.windsurf",
    ]

    static func focus(_ s: ClaudeSession) {
        guard let app = hostApp(of: s.pid) else { return }
        let bid = app.bundleIdentifier ?? ""

        if editors.contains(bid) || s.entrypoint == "claude-vscode", let appURL = app.bundleURL {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            NSWorkspace.shared.open([URL(fileURLWithPath: s.cwd, isDirectory: true)],
                                    withApplicationAt: appURL, configuration: cfg)
            return
        }
        if let tty = Proc.tty(s.pid), let script = tabScript(bundle: bid, tty: tty) {
            DispatchQueue.global(qos: .userInitiated).async {
                var err: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&err)
            }
        }
        app.activate()
    }

    /// Walks up the process tree to the first ordinary app (Terminal, iTerm, VS Code…).
    /// Falls back to the bundle id macOS leaves in the environment, which survives tmux.
    static func hostApp(of pid: pid_t) -> NSRunningApplication? {
        var p: pid_t? = pid
        for _ in 0..<32 {
            guard let cur = p else { break }
            if let app = NSRunningApplication(processIdentifier: cur), app.activationPolicy == .regular {
                return app
            }
            p = Proc.parent(cur)
        }
        if let bid = Proc.env(pid, "__CFBundleIdentifier") {
            return NSRunningApplication.runningApplications(withBundleIdentifier: bid).first
        }
        return nil
    }

    private static func tabScript(bundle: String, tty: String) -> String? {
        switch bundle {
        case "com.apple.Terminal":
            return """
            tell application "Terminal"
                repeat with w in windows
                    repeat with t in tabs of w
                        if tty of t is "\(tty)" then
                            set selected of t to true
                            set index of w to 1
                        end if
                    end repeat
                end repeat
            end tell
            """
        case "com.googlecode.iterm2":
            return """
            tell application "iTerm2"
                repeat with w in windows
                    repeat with t in tabs of w
                        repeat with s in sessions of t
                            if tty of s is "\(tty)" then
                                select w
                                select t
                                select s
                            end if
                        end repeat
                    end repeat
                end repeat
            end tell
            """
        default:
            return nil
        }
    }
}
