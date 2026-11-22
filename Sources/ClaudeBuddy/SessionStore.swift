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
            return "Finished, your turn"
        }
    }
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [ClaudeSession] = []
    @Published private(set) var alerts: [SessionAlert] = []
    /// Bumped whenever the buddy should hop and get your attention.
    @Published private(set) var nudge = 0
    /// Bumped whenever a session appears, leaves or changes status, so the buddy can react.
    private(set) var changeSerial = 0
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
    private var demo: [ClaudeSession]?
    private var demoClock = 0
    private var statuses: [String: String] = [:]
    private var hosts: [String: String] = [:]

    func start() {
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.scan() }
        }
    }

    /// Fake sessions for `--demo`, so the UI can be seen without real ones. When `animated`, they
    /// change state on a 70-second loop: alerts, everyone working, all quiet, then nothing running.
    func startDemo(animated: Bool = true) {
        demo = []
        demoClock = 0
        demoStep(quiet: !animated)
        guard animated else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.demoClock = (self.demoClock + 1) % 70
                self.demoStep()
            }
        }
    }

    private func demoStep(quiet: Bool = false) {
        let now = Date()
        func set(_ n: String, _ st: String, _ w: String? = nil, editor: Bool = true, age: TimeInterval = 0) {
            let old = demo?.first { $0.sessionId == n }
            if let old, old.status == st, old.waitingFor == w { return }
            let s = ClaudeSession(pid: 0, sessionId: n, name: n, cwd: "/tmp/\(n)", status: st, waitingFor: w,
                                  entrypoint: editor ? "claude-vscode" : "cli",
                                  startedAt: old?.startedAt ?? now.addingTimeInterval(Double(demo?.count ?? 0)),
                                  statusUpdatedAt: now.addingTimeInterval(-age))
            if let i = demo?.firstIndex(where: { $0.sessionId == n }) { demo?[i] = s } else { demo?.append(s) }
        }
        switch demoClock {
        case 0:
            set("Alpha USA", "waiting", "Bash(npm run build)")
            set("Practise 2", "idle", editor: false)
            set("Allendale", "busy")
            set("Darkroom", "idle", age: 6 * 3600)
            set("Wela", "busy", editor: false)
        case 12: set("Alpha USA", "busy")
        case 16: set("Practise 2", "busy", editor: false)
        case 28: set("Allendale", "idle")
        case 34: set("Wela", "idle", editor: false)
        case 40:
            set("Allendale", "busy")
            set("Wela", "busy", editor: false)
        case 44: set("Alpha USA", "waiting", "Edit(src/app.tsx)")
        case 52:
            for s in demo ?? [] { set(s.sessionId, "idle", editor: s.entrypoint == "claude-vscode") }
        case 62: demo = []
        default: break
        }
        ingest(demo ?? [], quiet: quiet || demoClock == 52)
        if demoClock == 52 { acknowledgeAll() }
    }

    /// Fixed sessions for `--film`, given as two states in a row so a busy session can be seen to
    /// finish. Nothing is read from disk and no timer runs.
    func showFilm(_ before: [ClaudeSession], _ after: [ClaudeSession]) {
        demo = before
        ingest(before, quiet: true)
        demo = after
        ingest(after, quiet: true)
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
        ingest(live, quiet: quiet)
    }

    /// Works out which sessions are waiting for you, and chimes for the new ones.
    private func ingest(_ live: [ClaudeSession], quiet: Bool) {
        let seen = Dictionary(live.map { ($0.id, $0.status) }, uniquingKeysWith: { a, _ in a })
        if seen != statuses {
            statuses = seen
            changeSerial += 1
            hosts = hosts.filter { seen[$0.key] != nil }
        }

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
        acknowledged.formIntersection(live.map(\.id))

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

    /// Every live session, most urgent first: needs you, your turn, working, then idle.
    var ordered: [ClaudeSession] {
        func rank(_ s: ClaudeSession) -> Int {
            if let a = alert(for: s) { return a.kind == .blocked ? 0 : 1 }
            return s.isBusy ? 2 : 3
        }
        return sessions.sorted {
            let (a, b) = (rank($0), rank($1))
            return a != b ? a < b : $0.statusUpdatedAt > $1.statusUpdatedAt
        }
    }

    /// The session the buddy is reacting to right now.
    var focusSession: ClaudeSession? {
        guard let first = ordered.first else { return nil }
        return alert(for: first) != nil || first.isBusy ? first : nil
    }

    func alert(for s: ClaudeSession) -> SessionAlert? { alerts.first { $0.id == s.id } }

    /// What a session is doing, in a few words.
    func activity(_ s: ClaudeSession) -> String {
        if let a = alert(for: s) { return a.detail }
        if s.isBlocked { return "Waiting for your answer" }
        return s.isBusy ? "Working…" : "Idle"
    }

    /// The app a session runs in ("Code", "Terminal"…), looked up once per session.
    func hostName(_ s: ClaudeSession) -> String {
        if let hit = hosts[s.id] { return hit }
        let name = s.pid > 0
            ? Activator.hostApp(of: s.pid)?.localizedName ?? (s.entrypoint == "claude-vscode" ? "VS Code" : "Terminal")
            : (s.entrypoint == "claude-vscode" ? "VS Code" : "Terminal")
        hosts[s.id] = name
        return name
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
