import Darwin
import Foundation

/// Small wrappers over sysctl for reading other processes owned by this user.
enum Proc {
    private static func info(_ pid: pid_t) -> kinfo_proc? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info
    }

    static func parent(_ pid: pid_t) -> pid_t? {
        guard let i = info(pid) else { return nil }
        let p = i.kp_eproc.e_ppid
        return p > 1 ? p : nil
    }

    static func startTime(_ pid: pid_t) -> Date? {
        guard let i = info(pid) else { return nil }
        let tv = i.kp_proc.p_un.__p_starttime
        return Date(timeIntervalSince1970: Double(tv.tv_sec) + Double(tv.tv_usec) / 1_000_000)
    }

    /// "/dev/ttys003" for a process attached to a terminal.
    static func tty(_ pid: pid_t) -> String? {
        guard let i = info(pid) else { return nil }
        let dev = i.kp_eproc.e_tdev
        guard dev != -1, dev != 0, let name = devname(dev, S_IFCHR) else { return nil }
        return "/dev/" + String(cString: name)
    }

    /// One environment variable of another process, via KERN_PROCARGS2.
    static func env(_ pid: pid_t, _ key: String) -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buf, &size, nil, 0) == 0, size > 4 else { return nil }

        let argc = buf.withUnsafeBytes { $0.load(as: Int32.self) }
        var i = 4
        while i < size, buf[i] != 0 { i += 1 }          // exec path
        while i < size, buf[i] == 0 { i += 1 }          // padding
        var seen: Int32 = 0
        while i < size, seen < argc {                    // argv
            while i < size, buf[i] != 0 { i += 1 }
            i += 1; seen += 1
        }
        let prefix = Array((key + "=").utf8)
        while i < size {                                 // envp
            let start = i
            while i < size, buf[i] != 0 { i += 1 }
            if i == start { break }
            let entry = buf[start..<i]
            if entry.starts(with: prefix) {
                return String(decoding: entry.dropFirst(prefix.count), as: UTF8.self)
            }
            i += 1
        }
        return nil
    }
}
