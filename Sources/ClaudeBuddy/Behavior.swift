import AppKit
import Combine
import QuartzCore
import SwiftUI

/// What the buddy is doing. The first nine can be picked by hand; the last two only ever come
/// from a session that is waiting for you, and always win over a picked behaviour.
enum Behavior: String, CaseIterable, Identifiable {
    case idle, working, thinking, walking, following, watching, sleeping, happy, curious
    case yourTurn, needsYou

    static let pickable: [Behavior] = [.idle, .working, .thinking, .walking, .following,
                                       .watching, .sleeping, .happy, .curious]

    var id: String { rawValue }
    var isAlert: Bool { self == .yourTurn || self == .needsYou }

    var label: String {
        switch self {
        case .yourTurn: return "your turn"
        case .needsYou: return "needs you"
        default: return rawValue
        }
    }

    var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    var icon: String {
        switch self {
        case .idle: return "cup.and.saucer.fill"
        case .working: return "keyboard.fill"
        case .thinking: return "ellipsis.bubble.fill"
        case .walking: return "figure.walk"
        case .following: return "cursorarrow.motionlines"
        case .watching: return "eyes"
        case .sleeping: return "moon.zzz.fill"
        case .happy: return "music.note"
        case .curious: return "questionmark"
        case .yourTurn: return "checkmark"
        case .needsYou: return "exclamationmark"
        }
    }

    var mood: Mood {
        switch self {
        case .working, .thinking: return .working
        case .sleeping: return .asleep
        case .happy, .yourTurn: return .done
        case .needsYou: return .needsYou
        default: return .idle
        }
    }
}

/// The slow-changing part of a frame: what SwiftUI needs for the name tag, glow and extras.
struct MascotStatus: Equatable {
    var mood = Mood.idle
    var label = "idle"
    var fx = Fx.none
    var alert = false
}

/// Carries frames from the engine to the screen. The buddy's own view listens to `frames` and
/// repaints itself; SwiftUI only hears about `status`, which changes a few times a minute.
@MainActor
final class FrameBox: ObservableObject {
    @Published private(set) var status = MascotStatus()
    /// Which character is on screen. Remembered between launches.
    @Published var look = Look(rawValue: UserDefaults.standard.string(forKey: "look") ?? "") ?? .cozy {
        didSet { if remember { UserDefaults.standard.set(look.rawValue, forKey: "look") } }
    }
    var remember = true
    let frames = CurrentValueSubject<MascotFrame, Never>(MascotFrame())

    var frame: MascotFrame { frames.value }

    func show(_ f: MascotFrame) {
        guard f != frames.value else { return }
        frames.send(f)
        let s = MascotStatus(mood: f.mood, label: f.label, fx: f.fx, alert: f.alert)
        if s != status { status = s }
    }
}

/// Small seedable random source, so snapshots come out the same every time.
struct Dice: RandomNumberGenerator {
    private var s: UInt64
    init(seed: UInt64) { s = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }
    mutating func next() -> UInt64 {
        s ^= s >> 12
        s ^= s << 25
        s ^= s >> 27
        return s &* 2_685_821_657_736_338_717
    }
}

/// The values the buddy is easing toward. Each behaviour writes targets here every tick and the
/// engine glides the real pose after them, so any change of behaviour blends instead of popping.
private struct Rig {
    var bodyX: CGFloat = 0, bodyY: CGFloat = 0, tilt: CGFloat = 0, squash: CGFloat = 1
    var lw: CGFloat = 12, lh: CGFloat = 8.5, rw: CGFloat = 12, rh: CGFloat = 8.5
    var la: CGFloat = 0, ra: CGFloat = 0, cut: CGFloat = 0, slant: CGFloat = 0
    var gx: CGFloat = 0, gy: CGFloat = 0
    /// Extra nod of the head (degrees, positive down) and turn of the whole body.
    var pitch: CGFloat = 0, turn: CGFloat = 0
    /// Eyebrows: lift and tilt for each, and how visible they are.
    var blY: CGFloat = 0, blA: CGFloat = 0, brY: CGFloat = 0, brA: CGFloat = 0, bO: CGFloat = 0
    /// Arms: swing forward and raise out to the side, in degrees, for each. And a forward lean.
    var alS: CGFloat = 0, alR: CGFloat = 12, arS: CGFloat = 0, arR: CGFloat = 12, lean: CGFloat = 0
    /// Colour of the headphones and other trim.
    var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0
    var blush: CGFloat = 0, glow: CGFloat = 1
    var lLift: CGFloat = 0, lDx: CGFloat = 0, rLift: CGFloat = 0, rDx: CGFloat = 0
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0

    mutating func approach(_ t: Rig, dt: CGFloat, gaze: CGFloat) {
        func k(_ rate: CGFloat) -> CGFloat { 1 - exp(-rate * dt) }
        let body = k(16), eye = k(22), feet = k(26), slow = k(6)
        bodyX += (t.bodyX - bodyX) * body
        bodyY += (t.bodyY - bodyY) * body
        tilt += (t.tilt - tilt) * k(12)
        squash += (t.squash - squash) * k(22)
        lw += (t.lw - lw) * eye
        lh += (t.lh - lh) * eye
        rw += (t.rw - rw) * eye
        rh += (t.rh - rh) * eye
        la += (t.la - la) * k(16)
        ra += (t.ra - ra) * k(16)
        pitch += (t.pitch - pitch) * k(14)
        turn += (t.turn - turn) * k(7)
        let brow = k(14)
        blY += (t.blY - blY) * brow
        blA += (t.blA - blA) * brow
        brY += (t.brY - brY) * brow
        brA += (t.brA - brA) * brow
        bO += (t.bO - bO) * k(9)
        let arm = k(13)
        alS += (t.alS - alS) * arm
        alR += (t.alR - alR) * arm
        arS += (t.arS - arS) * arm
        arR += (t.arR - arR) * arm
        lean += (t.lean - lean) * k(9)
        tr += (t.tr - tr) * slow
        tg += (t.tg - tg) * slow
        tb += (t.tb - tb) * slow
        cut += (t.cut - cut) * k(14)
        slant += (t.slant - slant) * k(12)
        gx += (t.gx - gx) * k(gaze)
        gy += (t.gy - gy) * k(gaze)
        blush += (t.blush - blush) * slow
        glow += (t.glow - glow) * k(4)
        lLift += (t.lLift - lLift) * feet
        rLift += (t.rLift - rLift) * feet
        lDx += (t.lDx - lDx) * k(20)
        rDx += (t.rDx - rDx) * k(20)
        r += (t.r - r) * slow
        g += (t.g - g) * slow
        b += (t.b - b) * slow
    }
}

/// One short stretch of a behaviour: a glance, a hop, a pause. Behaviours string these together
/// at random so they never loop the same way twice.
private struct Beat {
    var kind = -1
    var start = 0.0
    var end = 0.0
    var side: CGFloat = 1
    var a: CGFloat = 0
    var b: CGFloat = 0
    var tx: CGFloat = 0
    var ty: CGFloat = 0
}

private struct Walk {
    var x: CGFloat = 0
    var target: CGFloat = 0
    var phase: CGFloat = 0
    var going = false
    var until = 0.0
    var pausedAt = 0.0
    var gait = 0
    var trips = 0
    var dir: CGFloat = 1
    var nextDir: CGFloat = 1
}

/// Decides what the buddy does and works out every frame of it. It ticks 30 times a second but
/// only hands a frame to the screen when something visibly changed, and no more often than the
/// moment needs: 30 a second while you are watching, fewer while you are not, to keep the CPU quiet.
@MainActor
final class BehaviorEngine: ObservableObject {
    /// The behaviour picked by hand, or nil for Auto (the live sessions decide).
    @Published var pinned: Behavior? {
        didSet { if remember { UserDefaults.standard.set(pinned?.rawValue ?? "auto", forKey: "behavior") } }
    }
    @Published private(set) var current = Behavior.idle
    @Published var strollWhenIdle: Bool {
        didSet { UserDefaults.standard.set(strollWhenIdle, forKey: "strollWhenIdle") }
    }
    let screen = FrameBox()

    /// Called with the buddy's sideways offset from its home spot whenever it walks.
    var onWalk: ((CGFloat) -> Void)?
    /// How far from home it may walk, already limited to the screen.
    var walkRange: ClosedRange<CGFloat> = -110...110
    /// Centre of the buddy's head in screen coordinates.
    var headCenter: () -> CGPoint? = { nil }
    var cursor: () -> CGPoint = { NSEvent.mouseLocation }
    /// Overrides everything, for snapshots.
    var forced: Behavior?
    var remember = true

    private weak var store: SessionStore?
    private weak var ui: BuddyUI?
    private var dice: Dice
    private var timer: Timer?

    private var now = 0.0
    private var last = 0.0
    private var began = 0.0
    private var rig = Rig()
    private var T = Rig()
    private var fx = Fx.none
    private var gazeRate: CGFloat = 22
    private var beat = Beat()
    private var walk = Walk()
    private var reportedWalk: CGFloat = 0
    private var shownAt = -1.0
    private var autoSub = Behavior.idle
    private var autoUntil = 0.0

    private var blinkStart = -10.0
    private var nextBlink = 2.0
    private var blinkQueued = false
    private var blinkLength = 0.2
    private var drift = CGPoint.zero
    private var nextDrift = 0.0

    private var held = false
    private var heldAt = -10.0
    private var droppedAt = -10.0
    private var pokedAt = -10.0
    private var wokeAt = -10.0
    private var perkAt = -10.0
    private var askedAt = -10.0
    private var askSerial = 0
    private var flySerial = 0
    private var seenChange = 0
    private var wasBubbleOpen = false

    private var lastCursor = CGPoint.zero
    private var toCursor = CGPoint.zero
    private var cursorDist = CGFloat.infinity
    private var cursorStill = 0.0
    private var excite: CGFloat = 0
    private var lastHead: CGPoint?
    private var headVX: CGFloat = 0

    init(store: SessionStore?, ui: BuddyUI?, seed: UInt64? = nil) {
        self.store = store
        self.ui = ui
        dice = Dice(seed: seed ?? UInt64(Date().timeIntervalSince1970 * 1000))
        pinned = UserDefaults.standard.string(forKey: "behavior").flatMap(Behavior.init(rawValue:))
            .flatMap { Behavior.pickable.contains($0) ? $0 : nil }
        strollWhenIdle = UserDefaults.standard.object(forKey: "strollWhenIdle") as? Bool ?? true
        if seed != nil {  // a snapshot engine: start in Auto and leave the saved choice alone
            remember = false
            pinned = nil
        }
        let c = Mood.idle.rgb
        (rig.r, rig.g, rig.b) = (CGFloat(c.r), CGFloat(c.g), CGFloat(c.b))
        let n = Mood.neon
        (rig.tr, rig.tg, rig.tb) = (CGFloat(n.r), CGFloat(n.g), CGFloat(n.b))
    }

    func start() {
        guard timer == nil else { return }
        let t0 = CACurrentMediaTime()
        let t = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step(at: CACurrentMediaTime() - t0) }
        }
        t.tolerance = 0.004
        RunLoop.main.add(t, forMode: .common)
        timer = t
        step(at: 0)
    }

    /// Runs a behaviour from a standing start and returns the frames at the given times.
    func simulate(_ b: Behavior, at times: [Double]) -> [MascotFrame] {
        forced = b
        var out: [MascotFrame] = []
        var t = 0.0
        for want in times {
            while t < want {
                step(at: t)
                t += 1.0 / 30
            }
            out.append(screen.frame)
        }
        return out
    }

    // MARK: Things that happen to the buddy

    /// Picked up (true) or put down (false).
    func setHeld(_ on: Bool) {
        guard on != held else { return }
        held = on
        if on {
            heldAt = now
        } else {
            droppedAt = now
            blinkStart = now + 0.15
            nextBlink = now + 0.55
        }
    }

    /// Clicked.
    func poke() { pokedAt = now }

    /// The window was moved by hand, so wherever the buddy stands now is home.
    func resetWalk() {
        walk = Walk()
        reportedWalk = 0
    }

    // MARK: One tick

    func step(at time: Double) {
        let dt = CGFloat(max(0.001, min(0.1, time - last)))
        last = time
        now = time
        sense(dt)

        let next = forced ?? decide()
        if next != current { enter(next) }

        T = Rig()
        let c = current.mood.rgb, trim = current.isAlert ? current.mood.rgb : Mood.neon
        (T.r, T.g, T.b) = (CGFloat(c.r), CGFloat(c.g), CGFloat(c.b))
        (T.tr, T.tg, T.tb) = (CGFloat(trim.r), CGFloat(trim.g), CGFloat(trim.b))
        fx = .none
        gazeRate = 22

        // Away from home after a stroll: walk back first, but not while you are using the bubble.
        let homing = current != .walking && !current.isAlert && !held && !bubbleOpen && abs(walk.x) > 0.5
        if held {
            heldPose()
        } else if homing {
            stroll(dt, homing: true)
        } else {
            switch current {
            case .idle: idle()
            case .working: working()
            case .thinking: thinking()
            case .walking: stroll(dt, homing: false)
            case .following: following()
            case .watching: watching()
            case .sleeping: sleeping()
            case .happy: happy()
            case .curious: curious()
            case .yourTurn: yourTurn()
            case .needsYou: needsYou()
            }
            reactions()
        }
        liveEyes()

        rig.approach(T, dt: dt, gaze: gazeRate)
        publish()
    }

    private func publish() {
        var lid: CGFloat = 0
        if let gap = blinkGap, !held {
            if now >= nextBlink {
                blinkStart = now
                // Mostly quick blinks, now and then a slow, contented one.
                blinkLength = chance(0.14) ? 0.38 : 0.2
                if !blinkQueued, chance(0.18) {
                    nextBlink = now + 0.3
                    blinkQueued = true
                } else {
                    nextBlink = now + rand(gap)
                    blinkQueued = false
                }
            }
        }
        // Lids close fast, rest shut for an instant, and open more slowly.
        let d = (now - blinkStart) / blinkLength
        if d >= 0, d <= 1, current != .sleeping {
            lid = CGFloat(d < 0.35 ? d / 0.35 : d < 0.5 ? 1 : 1 - (d - 0.5) / 0.5)
        }

        let f = makeFrame(lid: lid)
        if now - shownAt >= 1 / frameRate - 0.004, f != screen.frame {
            shownAt = now
            screen.show(f)
        }

        func q(_ v: CGFloat, _ step: CGFloat) -> CGFloat { (v / step).rounded() * step }
        let x = q(walk.x, 0.5)
        if x != reportedWalk {
            reportedWalk = x
            onWalk?(x)
        }
    }

    /// One of the faces on its own, standing still, for the snapshot sheet.
    func still(_ f: Face, side: CGFloat = 1) -> MascotFrame {
        T = Rig()
        let c = Mood.idle.rgb, n = Mood.neon
        (T.r, T.g, T.b) = (CGFloat(c.r), CGFloat(c.g), CGFloat(c.b))
        (T.tr, T.tg, T.tb) = (CGFloat(n.r), CGFloat(n.g), CGFloat(n.b))
        face(f, side)
        rig = T
        return makeFrame(lid: 0)
    }

    private func makeFrame(lid: CGFloat) -> MascotFrame {
        func q(_ v: CGFloat, _ step: CGFloat) -> CGFloat { (v / step).rounded() * step }
        var f = MascotFrame()
        f.mood = current.mood
        f.label = current.label
        f.accent = RGB(r: Double(q(rig.r, 0.02)), g: Double(q(rig.g, 0.02)), b: Double(q(rig.b, 0.02)))
        f.trim = RGB(r: Double(q(rig.tr, 0.02)), g: Double(q(rig.tg, 0.02)), b: Double(q(rig.tb, 0.02)))
        f.armL = Arm(swing: q(rig.alS, 1), raise: q(rig.alR, 1))
        f.armR = Arm(swing: q(rig.arS, 1), raise: q(rig.arR, 1))
        f.lean = q(rig.lean, 0.5)
        f.glow = q(rig.glow, 0.05)
        f.bodyX = q(rig.bodyX, 0.5)
        f.bodyY = q(rig.bodyY, 0.5)
        f.tilt = q(rig.tilt, 0.5)
        f.squash = q(rig.squash, 0.01)
        f.eyeL = Eye(w: q(rig.lw, 0.25), h: q(max(1.8, rig.lh * (1 - lid)), 0.25), cut: q(rig.cut, 0.05),
                     slant: q(rig.slant, 0.5), arc: q(rig.la, 0.05))
        f.eyeR = Eye(w: q(rig.rw, 0.25), h: q(max(1.8, rig.rh * (1 - lid)), 0.25), cut: q(rig.cut, 0.05),
                     slant: q(rig.slant, 0.5), arc: q(rig.ra, 0.05))
        // The brows dip with the lids on a blink.
        f.browL = Brow(lift: q(rig.blY - lid * 1.2, 0.25), angle: q(rig.blA, 1))
        f.browR = Brow(lift: q(rig.brY - lid * 1.2, 0.25), angle: q(rig.brA, 1))
        f.brows = q(rig.bO, 0.05)
        f.gaze = CGPoint(x: q(rig.gx * 6, 0.25), y: q(rig.gy * 4, 0.25))
        // The head follows the eyes: it turns and nods part of the way toward where they look.
        f.yaw = q(rig.gx * 20, 0.5)
        f.pitch = q(rig.gy * 9 + rig.pitch, 0.5)
        f.turn = q(rig.turn, 0.5)
        f.blush = q(rig.blush, 0.1)
        f.footL = Foot(lift: q(max(0, rig.lLift), 0.5), dx: q(rig.lDx, 0.5))
        f.footR = Foot(lift: q(max(0, rig.rLift), 0.5), dx: q(rig.rDx, 0.5))
        f.fx = fx
        f.held = held
        f.alert = current.isAlert
        return f
    }

    // MARK: Choosing the behaviour

    private func decide() -> Behavior {
        guard let store else { return pinned ?? .idle }
        if !store.alerts.isEmpty {
            // Once you have dealt with it, carry on with what it was doing for a while.
            autoUntil = max(autoUntil, now + 8)
            return store.alerts.contains { $0.kind == .blocked } ? .needsYou : .yourTurn
        }
        if let pinned { return pinned }
        return auto(store)
    }

    /// Auto: the sessions decide. Busy means working with thinking breaks; quiet means idling,
    /// with the odd look around, tilt of the head, follow of the cursor or short stroll.
    private func auto(_ store: SessionStore) -> Behavior {
        if store.sessions.isEmpty {
            autoSub = .sleeping
            return .sleeping
        }
        if store.sessions.contains(where: \.isBusy) {
            if autoSub != .working, autoSub != .thinking {
                autoSub = .working
                autoUntil = now + rand(14...26)
            } else if now >= autoUntil {
                let toThinking = autoSub == .working
                autoSub = toThinking ? .thinking : .working
                autoUntil = now + (toThinking ? rand(4...7) : rand(14...26))
            }
            return autoSub
        }
        let calm: [Behavior] = [.idle, .watching, .curious, .walking, .following]
        if !calm.contains(autoSub) {
            autoSub = .idle
            autoUntil = now + rand(8...18)
        } else if autoSub == .walking {
            if walk.trips >= 1 || !strollWhenIdle || now >= autoUntil {
                autoSub = .idle
                autoUntil = now + rand(15...35)
            }
        } else if now >= autoUntil {
            if autoSub != .idle {
                autoSub = .idle
                autoUntil = now + rand(15...35)
            } else {
                var options: [(Behavior, Double, ClosedRange<Double>)] = [(.watching, 3, 6...10), (.curious, 2, 5...8)]
                if strollWhenIdle, !bubbleOpen { options.append((.walking, 2, 40...40)) }
                if cursorDist < 320 { options.append((.following, 2.5, 5...9)) }
                var r = Double.random(in: 0..<options.reduce(0) { $0 + $1.1 }, using: &dice)
                var pick = options[0]
                for o in options {
                    if r < o.1 { pick = o; break }
                    r -= o.1
                }
                autoSub = pick.0
                autoUntil = now + rand(pick.2)
            }
        }
        return autoSub
    }

    private func enter(_ next: Behavior) {
        let prev = current
        current = next
        began = now
        if forced == nil { print("behaviour: \(next.label)") }
        beat = Beat(kind: -1, start: now, end: now)
        if prev == .sleeping {
            // Wake with a start, then blink twice.
            wokeAt = now
            blinkStart = now + 0.4
            nextBlink = now + 0.8
            blinkQueued = true
        } else {
            // A blink hides the change of expression.
            if next != .sleeping, next != .needsYou { blinkStart = now }
            nextBlink = now + rand(1.2...3)
        }
        if next == .walking {
            walk.going = false
            walk.pausedAt = now
            walk.until = now + 0.6
            walk.trips = 0
            planWalk()
        }
        if next == .curious { ask() }
    }

    /// True while you are probably looking at the buddy: the cursor is close to it, you are
    /// using its bubble, or it has only just started doing something new.
    private var watched: Bool {
        if let fixed = Self.watchedOverride { return fixed }
        return cursorDist < 260 || bubbleOpen || now - began < 2.5
    }

    /// Debug: BUDDY_WATCHED=1 or 0 pins `watched`, to measure the smooth and the economy rates.
    private static let watchedOverride = ProcessInfo.processInfo.environment["BUDDY_WATCHED"].map { $0 == "1" }

    /// How many frames a second this moment deserves. Quick reactions and blinks always get the
    /// full 30. Otherwise it is 30 while you are watching, and a slower, cheaper rate while your
    /// attention is elsewhere on the screen, which is most of the day.
    private var frameRate: Double {
        let quick = held || now - began < 0.5 || now - blinkStart < blinkLength + 0.05 || now - pokedAt < 0.8
            || now - perkAt < 1.3 || now - droppedAt < 1.2 || now - wokeAt < 0.7
            || (ui.map { Date().timeIntervalSince($0.nudgedAt) < 2 } ?? false)
        if quick || forced != nil { return 30 }
        let near = watched
        let onTheMove = abs(walk.x) > 0.5 && !bubbleOpen && (current != .walking || walk.going)
        if onTheMove { return near ? 30 : 15 }
        switch current {
        case .sleeping: return near ? 15 : 6
        case .idle, .watching, .walking: return near ? 30 : 10
        case .following: return cursorStill < 0.6 ? 30 : 10
        default: return near ? 30 : 15
        }
    }

    private var blinkGap: ClosedRange<Double>? {
        switch current {
        case .sleeping: return nil
        case .happy, .yourTurn: return 3...7
        case .needsYou: return 1.5...3.5
        case .following: return 4...9
        case .working: return 3...7
        case .thinking, .curious: return 2...5
        default: return 2.5...6
        }
    }

    // MARK: Senses

    private var bubbleOpen: Bool {
        guard let ui else { return false }
        return ui.hovering || ui.pinnedOpen || (ui.announcing && !(store?.alerts.isEmpty ?? true))
    }

    private func sense(_ dt: CGFloat) {
        let c = cursor()
        let moved = hypot(c.x - lastCursor.x, c.y - lastCursor.y)
        excite = max(excite - dt * 1.4, min(1, moved / dt / 1600))
        cursorStill = moved < 1.5 ? cursorStill + Double(dt) : 0
        lastCursor = c
        if let h = headCenter() {
            toCursor = CGPoint(x: c.x - h.x, y: c.y - h.y)
            cursorDist = hypot(toCursor.x, toCursor.y)
            if let p = lastHead { headVX += ((h.x - p.x) / dt - headVX) * 0.3 }
            lastHead = h
        } else {
            cursorDist = .infinity
        }

        // Something happened nearby: a session changed state, or the bubble opened.
        let calm = [.idle, .watching, .curious, .following].contains(current)
        if let store, store.changeSerial != seenChange {
            seenChange = store.changeSerial
            if calm, now > 1 { perk() }
        }
        let open = bubbleOpen
        if open, !wasBubbleOpen, current == .curious { perk() }
        wasBubbleOpen = open
    }

    private func perk() {
        perkAt = now
        if current == .curious { ask() }
    }

    private func ask() {
        askedAt = now
        askSerial += 1
    }

    /// Where the eyes should point to look at the cursor: gentle when it is close, full when far.
    private func cursorGaze() -> CGPoint {
        guard cursorDist.isFinite else { return .zero }
        let k = 1.35 / (cursorDist + 150)
        return CGPoint(x: clamp(toCursor.x * k), y: clamp(-toCursor.y * k))
    }

    // MARK: Small helpers

    private func rand(_ r: ClosedRange<Double>) -> Double { Double.random(in: r, using: &dice) }
    private func chance(_ p: Double) -> Bool { Double.random(in: 0..<1, using: &dice) < p }
    private func clamp(_ v: CGFloat, _ lim: CGFloat = 1) -> CGFloat { max(-lim, min(lim, v)) }
    private func bump(_ x: CGFloat) -> CGFloat { sin(.pi * max(0, min(1, x))) }

    /// Seconds since this behaviour began, and since this beat began.
    private var t: CGFloat { CGFloat(now - began) }
    private var bt: CGFloat { CGFloat(now - beat.start) }
    /// Progress through the current beat, 0…1.
    private var p: CGFloat { CGFloat((now - beat.start) / max(0.01, beat.end - beat.start)) }

    /// Starts the next beat if the last one is over. Kinds other than 0 never run twice in a row.
    @discardableResult
    private func nextBeat(_ options: [(kind: Int, weight: Double, seconds: ClosedRange<Double>)]) -> Bool {
        guard now >= beat.end else { return false }
        var opts = options.filter { $0.kind == 0 || $0.kind != beat.kind }
        if opts.isEmpty { opts = options }
        var r = Double.random(in: 0..<opts.reduce(0) { $0 + $1.weight }, using: &dice)
        var pick = opts[0]
        for o in opts {
            if r < o.weight { pick = o; break }
            r -= o.weight
        }
        beat = Beat(kind: pick.kind, start: now, end: now + rand(pick.seconds),
                    side: chance(0.5) ? 1 : -1,
                    a: CGFloat(rand(-1...1)), b: CGFloat(rand(0...1)))
        return true
    }

    // MARK: Arms and eyes

    /// Sets both arms: (swing forward, raise outward) in degrees for the left, then the right.
    private func arms(l: (CGFloat, CGFloat), r: (CGFloat, CGFloat)) {
        (T.alS, T.alR, T.arS, T.arR) = (l.0, l.1, r.0, r.1)
    }

    private func armsBoth(swing: CGFloat = 0, raise: CGFloat) { arms(l: (swing, raise), r: (swing, raise)) }

    /// The arm on `side` takes `lead`; the other hangs, or takes `other`.
    private func arm(_ side: CGFloat, _ lead: (CGFloat, CGFloat), other: (CGFloat, CGFloat) = (0, 12)) {
        if side > 0 { arms(l: other, r: lead) } else { arms(l: lead, r: other) }
    }

    /// Eyes are never quite still: while awake they make tiny darting movements a few times a second.
    private func liveEyes() {
        guard current != .sleeping, !held else { return }
        if now >= nextDrift {
            nextDrift = now + rand(0.35...1.5)
            drift = CGPoint(x: rand(-0.07...0.07), y: rand(-0.05...0.05))
        }
        T.gx += drift.x
        T.gy += drift.y
    }

    // MARK: Expressions

    /// The faces Vertex can pull. Each sets the eyes and eyebrows together; behaviours pick one
    /// per beat and add the matching body movement.
    enum Face: String, CaseIterable {
        case neutral, happy, excited, curious, confused, sleepy, surprised, playful, focused, worried, pondering, sneaky
    }

    /// `side` picks which eye leads for the lopsided faces (1 the right eye, -1 the left).
    private func face(_ f: Face, _ side: CGFloat = 1) {
        func eyes(lead: CGFloat, other: CGFloat) {
            if side > 0 { T.rh = lead; T.lh = other } else { T.lh = lead; T.rh = other }
        }
        func brows(lead: (CGFloat, CGFloat), other: (CGFloat, CGFloat), show: CGFloat = 1) {
            if side > 0 { (T.brY, T.brA, T.blY, T.blA) = (lead.0, lead.1, other.0, other.1) }
            else { (T.blY, T.blA, T.brY, T.brA) = (lead.0, lead.1, other.0, other.1) }
            T.bO = show
        }
        switch f {
        case .neutral:
            break
        case .happy:  // smiling eyes, soft raised brows, blush
            T.la = 1; T.ra = 1; T.lh = 9; T.rh = 9
            T.blush = 1
            brows(lead: (2, -6), other: (2, -6), show: 0.85)
        case .excited:  // big bright eyes, brows right up
            T.lw = 13; T.rw = 13; T.lh = 12.5; T.rh = 12.5
            T.blush = 0.7
            brows(lead: (4, -8), other: (4, -8))
        case .curious:  // one eye bigger, its brow raised
            eyes(lead: 11.5, other: 7.5)
            brows(lead: (3.5, -6), other: (0.5, 4))
        case .confused:  // lopsided eyes, brows pulling opposite ways
            eyes(lead: 10.5, other: 6.5)
            T.cut = 0.12
            brows(lead: (3.5, -12), other: (-0.5, 12))
        case .sleepy:  // heavy lids, drooping brows
            T.lh = 5; T.rh = 5; T.cut = 0.4
            brows(lead: (-0.5, -12), other: (-0.5, -12), show: 0.7)
        case .surprised:  // tall round eyes, brows shot up
            T.lw = 10; T.rw = 10; T.lh = 13; T.rh = 13
            brows(lead: (5, -4), other: (5, -4))
        case .playful:  // a wink: one eye smiles shut, the other stays open with its brow up
            if side > 0 { T.la = 1; T.lh = 8; T.rh = 10.5 } else { T.ra = 1; T.rh = 8; T.lh = 10.5 }
            T.blush = 0.8
            brows(lead: (3.5, -5), other: (0.5, 8))
        case .focused:  // narrowed eyes under a determined frown
            T.lw = 12.5; T.rw = 12.5; T.lh = 8; T.rh = 8
            T.cut = 0.42; T.slant = 3.5
            brows(lead: (-1, 12), other: (-1, 12))
        case .worried:  // wide eyes, brows tipped up in the middle
            T.lw = 10.5; T.rw = 10.5; T.lh = 12.5; T.rh = 12.5
            brows(lead: (3.5, -16), other: (3.5, -16))
        case .pondering:  // one eye squints while the other brow lifts
            eyes(lead: 10, other: 5.2)
            T.cut = 0.15
            brows(lead: (3, -6), other: (-0.5, 8))
        case .sneaky:  // slitted eyes, brows low
            T.lh = 6; T.rh = 6; T.cut = 0.2
            brows(lead: (-0.5, 9), other: (-0.5, 9), show: 0.9)
        }
    }

    // MARK: Behaviours

    private func idle() {
        nextBeat([(0, 5, 2...5), (1, 3, 0.8...1.6), (2, 2, 1.4...2), (3, 1.5, 1.6...2.6), (4, 0.7, 2.4...3),
                  (5, 0.8, 1.2...1.8), (6, 0.6, 1.8...2.4), (7, 0.9, 2...3)])
        // Breathing: the body rises and the arms drift with it.
        let breath = sin(t * 1.7)
        T.bodyY = 0.9 * breath
        armsBoth(raise: 12 + 1.5 * breath)
        switch beat.kind {
        case 1:  // glance to one side, brows lifting as the eyes move
            T.gx = beat.side * 0.85
            T.gy = beat.a * 0.25
            if p < 0.4 { (T.blY, T.brY, T.bO) = (1.5, 1.5, 0.5) }
        case 2:  // shift the weight onto one foot, the other taps
            let s = bump(p)
            T.bodyX = beat.side * 2.6 * s
            T.tilt = beat.side * 2.5 * s
            let tap = 3.5 * max(0, sin(bt * 9)) * s
            if beat.side > 0 { T.lLift = tap } else { T.rLift = tap }
            arm(-beat.side, (0, 12 + 12 * s))
        case 3:  // tilt the head, a little curious
            face(.curious, beat.side)
            T.tilt = beat.side * 6.5
            T.gx = -beat.side * 0.3
        case 4:  // a big yawn and a stretch, arms up over the head
            let s = bump(p)
            face(.sleepy)
            T.lh = 8.5 - 5.5 * s
            T.rh = T.lh
            T.cut = 0.4 * s
            T.bO = 0.7 * s
            T.bodyY += 3 * s
            T.pitch = -6 * s
            T.tilt = beat.side * 2 * s
            armsBoth(swing: -8 * s, raise: 12 + 150 * s)
        case 5:  // a small contented smile
            face(.happy)
            T.blush = 0.5
            T.bodyY += 1.2 * bump(p)
        case 6:  // a little wave at you
            face(.happy)
            T.blush = 0.6
            T.tilt = beat.side * 4
            arm(beat.side, (0, 138 + 16 * sin(bt * 11)))
        case 7:  // rock on its heels, hands behind its back, looking about
            T.lean = 4 * sin(bt * 3)
            T.gx = 0.45 * sin(bt * 1.5)
            T.gy = -0.3
            armsBoth(swing: -16, raise: 9)
            (T.blY, T.brY, T.bO) = (1, 1, 0.4)
        default:
            T.gx = 0.12 * sin(t * 0.6)
        }
    }

    private func working() {
        nextBeat([(0, 6, 2.2...4.5), (1, 1.5, 0.8...1.2), (2, 1.5, 0.9...1.4)])
        fx = .dots
        T.lean = 4
        switch beat.kind {
        case 1:  // look up at you for a moment, hands hovering
            T.lw = 12.5; T.rw = 12.5; T.lh = 9.5; T.rh = 9.5
            T.gy = -0.25
            (T.blY, T.brY, T.bO) = (2, 2, 0.7)
            armsBoth(swing: 48, raise: 14)
        case 2:  // stop and consider, a hand to the chin
            face(.pondering, beat.side)
            T.gx = 0.5 * beat.side
            T.gy = -0.55
            T.tilt = beat.side * 3
            arm(beat.side, (78, 26), other: (45, 14))
        default:  // eyes sweep along the line like reading, head nods, hands type
            face(.focused)
            let line = 1.25 + 0.35 * beat.b
            let along = (bt / line).truncatingRemainder(dividingBy: 1)
            T.gx = -0.6 + 1.2 * along
            T.gy = 0.6 + 0.06 * sin(bt * 9)
            gazeRate = 30
            let nod = abs(sin(bt * 10.5))
            T.bodyY = -1.4 * nod
            T.pitch = 3.5 * nod
            T.rLift = 2.8 * max(0, sin(bt * 8.4))
            let key = 8 * sin(bt * 21)
            arms(l: (56 + key, 14), r: (56 - key, 14))
        }
    }

    private func thinking() {
        nextBeat([(0, 5, 2.4...4.5), (1, 1, 0.9...1.1), (2, 2, 1.5...2.5), (3, 1.2, 1.6...2.2)])
        fx = .thought
        let s = beat.side
        switch beat.kind {
        case 1:  // aha! arms up, a hop
            face(.excited)
            T.gy = -0.1
            let hop = 5 * bump(p)
            T.bodyY = hop
            T.lLift = hop * 0.8
            T.rLift = hop * 0.8
            armsBoth(raise: 20 + 135 * bump(p))
        case 3:  // stuck: frown at the floor and scratch its head
            face(.confused, s)
            T.gx = -s * 0.4
            T.gy = 0.55
            T.tilt = -s * 5
            T.bodyX = 1.5 * sin(t * 0.9)
            arm(s, (10, 150 + 7 * sin(bt * 10)))
        default:  // gaze drifts up to one side, a hand to the chin, while it works it out
            face(.pondering, -s)
            T.gx = s * 0.7 + 0.08 * sin(bt * 1.3)
            T.gy = -0.7
            T.tilt = s * 7
            T.bodyX = 2.2 * sin(t * 0.9)
            let tap = 2.5 * max(0, sin(bt * 3.2))
            if s > 0 { T.lLift = tap } else { T.rLift = tap }
            arm(s, (80, 26), other: (30, 8))
            gazeRate = 9
        }
    }

    private func following() {
        let g = cursorGaze()
        T.gx = g.x
        T.gy = g.y
        gazeRate = 14
        T.tilt = g.x * 4
        T.turn = g.x * 16
        T.bodyX = g.x * 2.5
        T.bodyY = max(0, -g.y) * 1.5 + 0.6 * sin(t * 1.7)
        if cursorDist < 80 {  // right next to it: delighted, arms up
            face(.happy)
            T.bodyY += 2.5 * abs(sin(t * 6))
            armsBoth(raise: 125 + 14 * sin(t * 9))
        } else if excite > 0.25 {  // the cursor is darting about
            face(.excited)
            T.lh = 9 + 3.5 * excite
            T.rh = T.lh
            T.bO = min(1, excite * 2)
            armsBoth(raise: 12 + 30 * excite)
        } else if cursorStill > 4 {  // nothing happening: relax
            T.lh = 7.5
            T.rh = 7.5
        } else {
            (T.blY, T.brY, T.bO) = (1.5, 1.5, 0.5)
            // Point a hand toward the cursor when it is off to one side.
            if abs(g.x) > 0.6 { arm(g.x > 0 ? 1 : -1, (10, 70)) }
        }
    }

    private func watching() {
        var beats: [(kind: Int, weight: Double, seconds: ClosedRange<Double>)] =
            [(0, 6, 0.8...2.6), (1, 2, 1.4...2.4), (2, 1.2, 1.1...1.3)]
        if t > 3 { beats.append((3, 1, Firefly.duration...Firefly.duration)) }
        if nextBeat(beats) {
            let spots: [(CGFloat, CGFloat)] = [(0.9, 0), (0.65, -0.6), (0, -0.8), (0.9, 0.35), (0.4, -0.3)]
            let s = spots[Int(beat.b * 4.99)]
            beat.tx = s.0 * beat.side
            beat.ty = s.1
            if beat.kind == 3 { flySerial += 1 }
        }
        T.bodyY = 0.6 * sin(t * 1.5)
        T.gx = beat.tx
        T.gy = beat.ty
        armsBoth(swing: -14, raise: 10)  // hands behind its back
        switch beat.kind {
        case 1:  // lean in, narrow the eyes and inspect
            face(.sneaky)
            T.lh = 5.5
            T.rh = 5.5
            T.tilt = beat.side * 2.5
            T.bodyX = beat.tx * 1.5
            T.lean = 7
        case 2:  // double-take
            if p > 0.35, p < 0.55 {
                T.gx = 0
                T.gy = 0
            } else if p >= 0.55 {
                face(.surprised)
                armsBoth(raise: 38)
            }
            gazeRate = 32
        case 3:  // a firefly drifts past; it reaches for it as it goes overhead
            let ltr = beat.side > 0
            let at = Firefly.point(p, leftToRight: ltr)
            T.gx = clamp((at.x - RobotArt.center) / 60)
            T.gy = clamp((at.y - RobotArt.headTop - 26) / 50)
            face(.curious, T.gx >= 0 ? 1 : -1)
            T.lh = 10
            T.rh = 10
            T.tilt = T.gx * 3
            if p > 0.3, p < 0.72 { arm(T.gx >= 0 ? 1 : -1, (10, 128), other: (-14, 10)) }
            gazeRate = 10
            fx = .firefly(flySerial, leftToRight: ltr)
        default:
            (T.blY, T.brY, T.bO) = (1, 1, 0.35)
        }
    }

    private func sleeping() {
        if t < 1.7 {  // one last yawn, with a stretch
            let s = bump(t / 1.7)
            face(.sleepy)
            T.lh = 8.5 - 6 * s
            T.rh = T.lh
            T.cut = 0.4 * s
            T.bodyY = 2.5 * s
            T.pitch = -6 * s
            T.tilt = 2 * s
            armsBoth(swing: -6 * s, raise: 12 + 140 * s)
            return
        }
        // Lids get heavy and it sits down, feet out in front, hands in its lap.
        let settle = min(1, (t - 1.7) / 1.2)
        T.lh = 8.5 - 4 * settle
        T.rh = T.lh
        T.la = -settle
        T.ra = -settle
        (T.blY, T.brY, T.blA, T.brA, T.bO) = (-1, -1, -10, -10, 0.55 * settle)
        T.bodyY = -7.5 * settle
        T.lDx = -3 * settle
        T.rDx = 3 * settle
        T.pitch = 12 * settle
        T.glow = 1 - 0.5 * settle
        armsBoth(swing: 24 * settle, raise: 12 - 6 * settle)
        guard settle >= 1 else { return }

        // Slow breathing: the body swells, the head sinks and rises, and it sways a little.
        fx = .zees
        let breath = sin(t * 1.3)
        T.bodyY = -7.5 + 0.7 * breath
        T.squash = 1 + 0.03 * breath
        T.pitch = 12 + 1.6 * breath
        T.tilt = 4 + 1.5 * sin(t * 0.55)
        armsBoth(swing: 24 + 2 * breath, raise: 6)
        nextBeat([(0, 6, 6...12), (1, 2, 0.5...0.6), (2, 1.2, 1.6...2), (3, 1.4, 1.8...2.4)])
        switch beat.kind {
        case 1:  // a foot twitches
            let twitch = 2.5 * bump(p)
            if beat.side > 0 { T.rLift = twitch } else { T.lLift = twitch }
        case 2:  // nods off further, then jolts back
            if p < 0.8 {
                T.pitch += 9 * (p / 0.8)
                T.tilt += 4 * (p / 0.8)
            } else {
                T.pitch -= 6
                T.bodyY += 2
            }
        case 3:  // snuggles down the other way
            let s = bump(p)
            T.bodyX = beat.side * 1.6 * s
            T.tilt -= 8 * s
            armsBoth(swing: 34, raise: 4)
        default:
            break
        }
    }

    private func happy() {
        nextBeat([(0, 4, 2.7...3.7), (1, 4, 2.6...4.2), (2, 1.4, 1...1.3), (3, 1.2, 0.9...1.2), (4, 1.6, 1.4...2),
                  (5, 1, 1.1...1.3)])
        // A twirl ends a full turn round; unwind it so the next turn starts from facing you.
        if beat.kind != 5, rig.turn > 180 { rig.turn -= 360 }
        fx = .notes
        face(.happy)
        armsBoth(raise: 28)
        switch beat.kind {
        case 1:  // dance from foot to foot, arms pumping in turn
            let s = sin(bt * 4.6)
            T.bodyX = 4 * s
            T.tilt = 6.5 * s
            T.turn = 9 * s
            T.lLift = 4.5 * max(0, -s)
            T.rLift = 4.5 * max(0, s)
            T.bodyY = 1.2 * abs(s)
            arms(l: (0, 95 - 45 * s), r: (0, 95 + 45 * s))
        case 2:  // wink, with a wave
            T.la = 0; T.ra = 0
            face(.playful, beat.side)
            T.tilt = beat.side * 5
            arm(beat.side, (0, 140 + 16 * sin(bt * 12)), other: (0, 20))
        case 3:  // wiggle, brows bobbing, hands shaking
            let w = sin(bt * 16)
            T.bodyX = 2.5 * w
            T.tilt = 3 * w
            T.blY = 2 + 1.5 * w
            T.brY = 2 - 1.5 * w
            arms(l: (0, 60 + 14 * w), r: (0, 60 - 14 * w))
        case 4:  // too excited to keep its eyes shut: quick little hops, arms up
            T.la = 0; T.ra = 0
            face(.excited)
            let hop = abs(sin(bt * 7))
            T.bodyY = 4 * hop
            T.lLift = 3.4 * hop
            T.rLift = 3.4 * hop
            armsBoth(raise: 135 + 12 * sin(bt * 14))
        case 5:  // a twirl on the spot
            let u = p * p * (3 - 2 * p)
            T.turn = 360 * u
            T.bodyY = 3 * bump(p)
            T.lLift = 2.5 * bump(p)
            T.rLift = 2.5 * bump(p)
            armsBoth(raise: 85)
        default:  // a proper jump: crouch, spring up with arms high, land with a squash
            let u = (bt / 0.95).truncatingRemainder(dividingBy: 1)
            if u < 0.24 {  // gather
                let a = sin(u / 0.24 * .pi / 2)
                T.bodyY = -4 * a
                T.squash = 1 + 0.08 * a
                T.lean = 4 * a
                armsBoth(swing: -28 * a, raise: 18)
            } else if u < 0.8 {  // in the air
                let h = sin((u - 0.24) / 0.56 * .pi)
                T.bodyY = 14 * h
                T.lLift = 12 * h
                T.rLift = 12 * h
                T.squash = 1 - 0.06 * h
                T.la = 0; T.ra = 0
                face(.excited)
                armsBoth(raise: 30 + 125 * h)
            } else {  // land
                let c = (u - 0.8) / 0.2
                T.bodyY = -2.5 * (1 - c)
                T.squash = 1 + 0.1 * (1 - c)
                armsBoth(raise: 45 * (1 - c) + 20)
            }
        }
    }

    private func curious() {
        if nextBeat([(0, 4, 1.6...3), (1, 2, 1.4...2.2), (2, 1.5, 1.2...1.8), (3, 1.5, 1.6...2.4)]) {
            beat.tx = beat.side * (0.5 + 0.4 * beat.b)
            beat.ty = beat.a * 0.5
            if beat.kind == 3 || (beat.kind != 2 && chance(0.5)) { ask() }
        }
        if now - askedAt < 1.8 { fx = .question(askSerial) }

        // The cursor moving close by is the most interesting thing around.
        if cursorDist < 190, cursorStill < 1.2 {
            let g = cursorGaze()
            let s: CGFloat = toCursor.x >= 0 ? 1 : -1
            face(.curious, s)
            T.gx = clamp(g.x * 1.8)
            T.gy = clamp(g.y * 1.8)
            T.bodyX = s * 3.5
            T.bodyY = -1
            T.tilt = s * 8
            T.turn = s * 10
            T.lean = 5
            arm(s, (15, 75))
            gazeRate = 14
            return
        }
        let s = beat.side
        switch beat.kind {
        case 1:  // lean right over for a peek
            face(.surprised)
            T.lh = 10.5; T.rh = 10.5
            T.bodyX = s * 4.5
            T.bodyY = -2.5
            T.tilt = s * 5
            T.turn = s * 14
            T.lean = 8
            T.gx = s * 0.95
            T.gy = 0.1
            armsBoth(swing: -18, raise: 16)
        case 2:  // stretch up on its toes and look overhead
            face(.curious, -s)
            T.gy = -0.85
            T.gx = beat.a * 0.3
            T.tilt = -s * 4
            T.bodyY = 2.5
            armsBoth(swing: -10, raise: 20)
        case 3:  // puzzled: head right over, scratching it
            face(.confused, s)
            T.tilt = -s * 9
            T.gx = -s * 0.35
            T.gy = 0.15
            T.bodyX = -s * 1.5
            arm(-s, (10, 150 + 7 * sin(bt * 10)))
        default:  // head on one side, one eye bigger than the other
            face(.curious, s)
            T.tilt = s * 8.5
            T.gx = beat.tx
            T.gy = beat.ty
            T.bodyX = s * 1.5
            arm(s, (30, 34))
        }
    }

    private func yourTurn() {
        nextBeat([(0, 5, 2.5...4), (1, 1.5, 1...1.4), (2, 1.5, 1.2...1.8)])
        switch beat.kind {
        case 1:  // look up at the bubble, pointing at it
            face(.excited)
            T.lh = 10.5; T.rh = 10.5
            T.gy = -0.8
            T.bodyY = 1.5
            arm(beat.side, (20, 160), other: (0, 20))
        case 2:  // a wink your way
            face(.playful, beat.side)
            T.tilt = beat.side * 5
            arm(beat.side, (0, 140 + 16 * sin(t * 12)), other: (0, 20))
        default:  // sway happily and wave
            let s = sin(t * 3.4)
            face(.happy)
            T.blush = 0.8
            T.bodyX = 3 * s
            T.tilt = 5 * s
            T.turn = 6 * s
            T.lLift = 3.5 * max(0, -s)
            T.rLift = 3.5 * max(0, s)
            arms(l: (0, 22), r: (0, 138 + 18 * sin(t * 10)))
        }
        nudgeHops()
    }

    private func needsYou() {
        face(.worried)
        T.gy = -0.35
        if t.truncatingRemainder(dividingBy: 2.2) < 1.3 {  // stomp from foot to foot, both arms waving
            let s = sin(t * 8.5)
            T.lLift = 5.5 * max(0, s)
            T.rLift = 5.5 * max(0, -s)
            T.bodyY = 2.2 * abs(s)
            T.tilt = 3 * s
            arms(l: (0, 140 + 26 * s), r: (0, 140 - 26 * s))
        } else {  // then stand on tiptoe, hands out, looking at you
            T.bodyY = 1.8
            T.gx = 0.3 * sin(t * 14)
            T.lean = 5
            armsBoth(swing: 30, raise: 55)
        }
        nudgeHops()
    }

    /// Three soft hops that shrink, whenever a session newly needs you.
    private func nudgeHops() {
        guard let ui else { return }
        let since = CGFloat(Date().timeIntervalSince(ui.nudgedAt))
        guard since < 1.8 else { return }
        let hop = abs(sin(since / 0.6 * .pi)) * (1 - since / 1.8)
        T.bodyY = 12 * hop
        T.lLift = 10 * hop
        T.rLift = 10 * hop
        T.bodyX = 0
        T.tilt = 0
        T.squash = hop < 0.12 ? 1.07 : 1
        armsBoth(raise: 40 + 110 * hop)
    }

    /// Picked up by the mouse: startled, body swinging behind the hand, arms and legs flailing.
    private func heldPose() {
        let ht = CGFloat(now - heldAt)
        let v = clamp(headVX / 700)
        face(.surprised)
        T.tilt = -v * 13 + 2.5 * sin(ht * 7)
        T.gx = v * 0.8
        T.gy = 0.25
        T.bodyY = 3
        T.lLift = 0.5
        T.rLift = 0.5
        T.lDx = 3 * sin(ht * 8) - v * 4
        T.rDx = 3 * sin(ht * 8 + 1.1) - v * 4
        arms(l: (0, 140 + 22 * sin(ht * 9)), r: (0, 140 - 22 * sin(ht * 9)))
    }

    /// Short reactions layered over whatever the buddy is doing.
    private func reactions() {
        let calm = [.idle, .watching, .walking, .curious].contains(current)
        if ui?.hovering == true, calm {  // looks at you and perks up
            let g = cursorGaze()
            T.gx = clamp(g.x * 2)
            T.gy = clamp(g.y * 2)
            T.lh += 1
            T.rh += 1
            T.blY = max(T.blY, 2)
            T.brY = max(T.brY, 2)
            T.bO = max(T.bO, 0.7)
            T.turn = 0
        }
        let perk = CGFloat(now - perkAt) / 1.2
        if perk < 1, !current.isAlert, current != .sleeping {  // something happened: look up, startled
            T.la = 0; T.ra = 0; T.cut = 0; T.slant = 0
            face(.surprised)
            T.gy = -0.8
            T.gx = 0
            let hop = 4 * bump(perk * 2.5)
            T.bodyY += hop
            T.lLift += hop * 0.8
            T.rLift += hop * 0.8
            armsBoth(raise: 45)
        }
        let poke = CGFloat(now - pokedAt) / 0.8
        if poke < 1, current != .sleeping {  // clicked: a pleased little hop, a wink and a wave
            T.la = 0; T.ra = 0; T.cut = 0; T.slant = 0
            T.lw = 12; T.rw = 12
            face(.playful, 1)
            let hop = 4 * bump(poke)
            T.bodyY += hop
            T.lLift += hop * 0.75
            T.rLift += hop * 0.75
            arm(1, (0, 140 + 16 * sin(poke * 22)), other: (0, 18))
        }
        let drop = CGFloat(now - droppedAt)
        if drop < 0.45 {  // put down: squash on landing, arms out for balance
            let u = drop / 0.45
            T.squash = 1 + 0.13 * (1 - u)
            T.lDx -= 2 * (1 - u)
            T.rDx += 2 * (1 - u)
            armsBoth(raise: 20 + 60 * (1 - u))
        }
        if drop < 1.1, !current.isAlert, current != .sleeping {  // ...and a dazed moment after
            T.la = 0; T.ra = 0; T.slant = 0
            face(.confused, 1)
            T.tilt = 5 * sin(drop * 9) * (1 - drop / 1.1)
        }
        let wake = CGFloat(now - wokeAt) / 0.6
        if wake < 1 {  // woken up with a start
            T.la = 0; T.ra = 0; T.cut = 0
            face(.surprised)
            T.bodyY += 3 * bump(wake)
            armsBoth(raise: 20 + 50 * bump(wake))
        }
    }

    // MARK: Walking

    private func planWalk() {
        if abs(walk.x) > 1 {
            walk.target = 0
        } else {
            let side: CGFloat = chance(0.5) ? 1 : -1
            let far = CGFloat(rand(45...110))
            var target = max(walkRange.lowerBound, min(walkRange.upperBound, side * far))
            if abs(target) < 20 { target = max(walkRange.lowerBound, min(walkRange.upperBound, -side * far)) }
            walk.target = target
        }
        walk.nextDir = walk.target >= walk.x ? 1 : -1
        let roll = rand(0...1)
        walk.gait = roll < 0.45 ? 0 : roll < 0.6 ? 1 : roll < 0.8 ? 2 : 3
    }

    private func arrive() {
        walk.going = false
        walk.pausedAt = now
        let home = abs(walk.x) < 1
        if home { walk.trips += 1 }
        walk.until = now + (home ? rand(2.2...4.5) : rand(1.0...2.4))
        planWalk()
    }

    /// A short stroll out from home and back. `homing` walks straight home before another behaviour starts.
    private func stroll(_ dt: CGFloat, homing: Bool) {
        T.bodyY = 0.7 * sin(CGFloat(now) * 1.7)
        if homing, !walk.going || walk.target != 0 {
            walk.target = 0
            walk.going = true
        }
        if homing { walk.gait = 3 }  // it runs home
        if !homing, bubbleOpen {  // stand still while you are using the bubble
            walk.until += Double(dt)
            return
        }
        guard walk.going else {
            // Paused: look around, then let the eyes turn before the body does.
            let since = CGFloat(now - walk.pausedAt)
            if walk.until - now < 0.5 {
                T.gx = walk.nextDir * 0.9
            } else if since > 0.3 {
                T.gx = 0.8 * sin(since * 2.3)
                T.gy = -0.15
            }
            if now >= walk.until { walk.going = true }
            return
        }

        // speed (pt/s), stride (pt per two steps), how high the feet lift
        let gaits: [(CGFloat, CGFloat, CGFloat)] = [(36, 17, 4.5), (15, 9, 2.4), (50, 24, 5), (82, 30, 7)]
        let (speed, stride, lift) = gaits[walk.gait]
        walk.dir = walk.target >= walk.x ? 1 : -1
        let step = speed * dt
        if abs(walk.target - walk.x) <= step {
            walk.x = walk.target
            arrive()
            return
        }
        walk.x += walk.dir * step
        walk.phase += step / stride * 2 * .pi
        if walk.x < walkRange.lowerBound || walk.x > walkRange.upperBound {
            walk.x = max(walkRange.lowerBound, min(walkRange.upperBound, walk.x))
            arrive()
            return
        }

        // A foot swings forward through the air for half the cycle, then stays planted on the
        // ground while the body passes over it, so it never slides.
        let reach = stride / 4
        let dir = walk.dir
        func foot(_ phase: CGFloat) -> Foot {
            let u = (phase / (2 * .pi)).truncatingRemainder(dividingBy: 1)
            if u < 0.5 {
                let s = u / 0.5
                return Foot(lift: lift * sin(.pi * s), dx: -dir * reach * cos(.pi * s))
            }
            return Foot(lift: 0, dx: dir * reach * (1 - 2 * (u - 0.5) / 0.5))
        }
        let l = foot(walk.phase), r = foot(walk.phase + .pi)
        (T.lLift, T.lDx, T.rLift, T.rDx) = (l.lift, l.dx, r.lift, r.dx)
        // The body turns to face the way it is going; arms swing against the legs.
        let swing = sin(walk.phase)
        T.bodyY = 1.5 * abs(swing)
        T.turn = dir * 40
        T.tilt = dir * 2.5 + 1.5 * swing
        T.bodyX = dir * 1.5
        T.gx = dir * 0.3
        T.gy = 0.05
        arms(l: (-24 * swing, 14), r: (24 * swing, 14))
        switch walk.gait {
        case 1:  // tiptoe, sneaking: up on its toes, elbows out, creeping
            face(.sneaky)
            T.bodyY += 2.5
            T.pitch = 5
            T.lean = 6
            T.tilt = dir * 4
            T.gx = dir * 0.6
            arms(l: (30 - 10 * swing, 30), r: (30 + 10 * swing, 30))
        case 2:  // skip, delighted, arms swinging high
            let hop = abs(swing)
            face(.happy)
            T.blush = 0.7
            T.bodyY = 6.5 * hop
            T.lLift = max(T.lLift, 4.5 * hop)
            T.rLift = max(T.rLift, 4.5 * hop)
            T.tilt = dir * 2 + 3 * swing
            arms(l: (-40 * swing, 40 + 30 * hop), r: (40 * swing, 40 + 30 * hop))
        case 3:  // run: leaning in, arms pumping, both feet leaving the ground
            let hop = abs(swing)
            face(.excited)
            T.lh = 10.5; T.rh = 10.5
            T.blush = 0.3
            T.lean = 13
            T.turn = dir * 48
            T.bodyY = 3.2 * hop
            T.lLift += 2 * hop
            T.rLift += 2 * hop
            T.tilt = dir * 1.5 + 2 * swing
            arms(l: (-52 * swing, 22), r: (52 * swing, 22))
        default:  // an easy stroll
            (T.blY, T.brY, T.bO) = (1.5, 1.5, 0.5)
        }
    }
}
