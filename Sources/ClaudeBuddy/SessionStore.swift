import AppKit
import Combine
import Darwin

/// One live Claude Code session, read from ~/.claude/sessions/<pid>.json.
/// Claude Code rewrites that file whenever the session's status changes
/// ("busy" while working, "idle"/"shell" when done, "waiting" when it needs you).
struct ClaudeSession: Identifiable, Equatable {
    let pid: pid_t
    let sessionId: String
    let name: String
    let cwd: String
    let status: String
    let waitingFor: String?
    let entrypoint: String
    let startedAt: Date
    let statusUpdatedAt: Date

    var id: String { sessionId }
    var project: String { URL(fileURLWithPath: cwd).lastPathComponent }
    var isBusy: Bool { status == "busy" }
    var isBlocked: Bool { status == "waiting" }
}

enum AlertKind { case blocked, done }

struct SessionAlert: Identifiable, Equatable {
    let session: ClaudeSession
    let kind: AlertKind
    var id: String { session.id }

    var title: String { session.project }
    var detail: String {
        switch kind {
        case .blocked:
            if let w = session.waitingFor, !w.isEmpty, w != "dialog open" { return "Needs you: \(w)" }
            return "Needs your answer"
        case .done:
            return "All done, your turn"
        }
    }
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [ClaudeSession] = []
    @Published private(set) var alerts: [SessionAlert] = []
    /// Bumped whenever the buddy should hop and get your attention.
    @Published private(set) var nudge = 0
    @Published var soundOn: Bool = UserDefaults.standard.object(forKey: "soundOn") as? Bool ?? true {
        didSet { UserDefaults.standard.set(soundOn, forKey: "soundOn") }
    }
    @Published var remindEvery: TimeInterval = UserDefaults.standard.object(forKey: "remindEvery") as? Double ?? 300 {
        didSet { UserDefaults.standard.set(remindEvery, forKey: "remindEvery") }
    }

    /// Idle sessions older than this when the buddy starts are treated as already seen.
    private let freshWindow: TimeInterval = 15 * 60
    private let launchedAt = Date()
    private let dir = ProcessInfo.processInfo.environment["CLAUDE_BUDDY_SESSIONS_DIR"].map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/sessions", isDirectory: true)

    /// Sessions you have already been told about (or opened) in the current waiting spell.
    /// A session leaves this set as soon as it goes busy again, so the next finish alerts anew.
    private var acknowledged: Set<String> = []
    private var known: Set<String> = []
    private var lastReminder = Date()
    private var timer: Timer?
    private var cache: [URL: (Date, ClaudeSession?)] = [:]
    private var demo: [SessionAlert]?

    func start() {
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.scan() }
        }
    }

    /// Fake alerts for `--demo`, so the UI can be seen without a real waiting session.
    func startDemo() {
        let now = Date()
        func s(_ n: String, _ st: String, _ w: String? = nil) -> ClaudeSession {
            ClaudeSession(pid: 0, sessionId: n, name: n, cwd: "/tmp/\(n)", status: st, waitingFor: w,
                          entrypoint: "cli", startedAt: now, statusUpdatedAt: now)
        }
        let a = [SessionAlert(session: s("Alpha USA", "waiting", "Bash(npm run build)"), kind: .blocked),
                 SessionAlert(session: s("Practise 2", "idle"), kind: .done)]
        demo = a
        sessions = a.map(\.session) + [s("Allendale", "busy")]
        alerts = a
        nudge += 1
    }

    func acknowledge(_ alert: SessionAlert) {
        acknowledged.insert(alert.id)
        alerts.removeAll { $0.id == alert.id }
    }

    func acknowledgeAll() {
        for a in alerts { acknowledged.insert(a.id) }
        alerts.removeAll()
    }

    func scan(quiet: Bool = false) {
        guard demo == nil else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]))?
            .filter { $0.pathExtension == "json" } ?? []

        var live: [ClaudeSession] = []
        for url in files {
            let mod = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let session: ClaudeSession?
            if let hit = cache[url], hit.0 == mod {
                session = hit.1
            } else {
                session = Self.parse(url)
                cache[url] = (mod, session)
            }
            if let s = session, Self.isAlive(s) { live.append(s) }
        }
        cache = cache.filter { files.contains($0.key) }
        live.sort { $0.startedAt < $1.startedAt }

        var newAlerts: [SessionAlert] = []
        var fresh: [SessionAlert] = []
        for s in live {
            let firstSight = !known.contains(s.id)
            known.insert(s.id)

            if s.isBusy {
                acknowledged.remove(s.id)
                continue
            }
            // On first sight, a session that went quiet long before the buddy started is old news.
            if firstSight && !s.isBlocked && s.statusUpdatedAt < launchedAt.addingTimeInterval(-freshWindow) {
                acknowledged.insert(s.id)
            }
            guard !acknowledged.contains(s.id) else { continue }

            let alert = SessionAlert(session: s, kind: s.isBlocked ? .blocked : .done)
            newAlerts.append(alert)
            if let old = alerts.first(where: { $0.id == alert.id }), old.kind == alert.kind { continue }
            fresh.append(alert)
        }
        known.formIntersection(live.map(\.id))

        if sessions != live { sessions = live }
        if alerts != newAlerts { alerts = newAlerts }

        if quiet { return }
        for a in fresh { print("alert: \(a.title) — \(a.detail)") }
        if !fresh.isEmpty {
            ping(fresh.contains { $0.kind == .blocked } ? "Ping" : "Glass")
        } else if !alerts.isEmpty, remindEvery > 0, Date().timeIntervalSince(lastReminder) >= remindEvery {
            ping("Tink")
        }
    }

    var mood: Mood {
        if alerts.contains(where: { $0.kind == .blocked }) { return .needsYou }
        if !alerts.isEmpty { return .done }
        if sessions.contains(where: \.isBusy) { return .working }
        return sessions.isEmpty ? .asleep : .idle
    }

    /// Plain-text summary for `ClaudeBuddy --status`.
    var report: String {
        if sessions.isEmpty { return "No live Claude sessions." }
        return sessions.map { s in
            let alert = alerts.first { $0.id == s.id }.map { " -> ALERT: \($0.detail)" } ?? ""
            let host = Activator.hostApp(of: s.pid)?.localizedName ?? "?"
            return "\(s.project)  [\(s.status)]  pid \(s.pid)  in \(host)\(alert)"
        }.joined(separator: "\n")
    }

    private func ping(_ sound: String) {
        lastReminder = Date()
        nudge += 1
        if soundOn { NSSound(named: NSSound.Name(sound))?.play() }
    }

    private static func parse(_ url: URL) -> ClaudeSession? {
        guard let data = try? Data(contentsOf: url),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pid = j["pid"] as? Int,
              let sid = j["sessionId"] as? String,
              let cwd = j["cwd"] as? String else { return nil }
        if let kind = j["kind"] as? String, kind != "interactive" { return nil }
        func date(_ key: String) -> Date {
            (j[key] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) } ?? .distantPast
        }
        return ClaudeSession(
            pid: pid_t(pid), sessionId: sid,
            name: j["name"] as? String ?? URL(fileURLWithPath: cwd).lastPathComponent,
            cwd: cwd,
            status: j["status"] as? String ?? "idle",
            waitingFor: j["waitingFor"] as? String,
            entrypoint: j["entrypoint"] as? String ?? "cli",
            startedAt: date("startedAt"),
            statusUpdatedAt: date("statusUpdatedAt"))
    }

    /// The pid must exist and must have started no later than the session did,
    /// so a recycled pid from a long-dead session is not mistaken for a live one.
    private static func isAlive(_ s: ClaudeSession) -> Bool {
        guard s.pid > 0, kill(s.pid, 0) == 0 || errno == EPERM else { return false }
        guard let started = Proc.startTime(s.pid) else { return true }
        return started <= s.startedAt.addingTimeInterval(5)
    }
}
