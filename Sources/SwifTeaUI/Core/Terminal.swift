import Foundation
#if os(Linux)
import Glibc
private let STDIN_FILENO_: Int32 = 0
#else
import Darwin
private let STDIN_FILENO_: Int32 = STDIN_FILENO
#endif

public struct TerminalSize: Equatable, Sendable {
    public var columns: Int
    public var rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = max(0, columns)
        self.rows = max(0, rows)
    }

    public static let zero = TerminalSize(columns: 0, rows: 0)
}

public enum TerminalDimensions {
    private static var currentSize = TerminalSize(columns: 80, rows: 24)
    private static var overrideStack: [TerminalSize] = []
    private static let overrideLock = NSLock()

    public static var current: TerminalSize {
        overrideLock.lock()
        let value = overrideStack.last ?? currentSize
        overrideLock.unlock()
        return value
    }

    @discardableResult
    public static func refresh() -> TerminalSize {
        overrideLock.lock()
        if let override = overrideStack.last {
            overrideLock.unlock()
            return override
        }
        overrideLock.unlock()

        let queried = queryTerminalSize()
        overrideLock.lock()
        currentSize = queried
        overrideLock.unlock()
        return queried
    }

    public static func withTemporarySize<T>(
        _ size: TerminalSize,
        _ perform: () throws -> T
    ) rethrows -> T {
        overrideLock.lock()
        overrideStack.append(size)
        overrideLock.unlock()
        defer {
            overrideLock.lock()
            overrideStack.removeLast()
            overrideLock.unlock()
        }
        return try perform()
    }

    private static func queryTerminalSize() -> TerminalSize {
        var ws = winsize()
        if ioctl(STDIN_FILENO_, TIOCGWINSZ, &ws) == 0 {
            return TerminalSize(columns: Int(ws.ws_col), rows: Int(ws.ws_row))
        }
        return currentSize
    }
}

@discardableResult
func setNonBlocking(_ fd: Int32, enabled: Bool) -> Int32 {
    let flags = fcntl(fd, F_GETFL)
    return fcntl(fd, F_SETFL, enabled ? (flags | O_NONBLOCK) : (flags & ~O_NONBLOCK))
}

func setRawMode() -> termios {
    var t = termios()
    tcgetattr(STDIN_FILENO_, &t)
    let original = t

    // Raw-ish: disable canonical mode (ICANON) and echo (ECHO)
    t.c_lflag &= ~(UInt(ICANON | ECHO))
    // Optional: also disable signals: t.c_lflag &= ~UInt(ISIG)

    tcsetattr(STDIN_FILENO_, TCSANOW, &t)
    _ = setNonBlocking(STDIN_FILENO_, enabled: true)
    return original
}

func restoreMode(_ original: termios) {
    var t = original
    tcsetattr(STDIN_FILENO_, TCSANOW, &t)
    _ = setNonBlocking(STDIN_FILENO_, enabled: false)
}

@inline(__always)
func clearScreenAndHome() {
    // ESC[2J = clear screen; ESC[H = cursor home
    print("\u{001B}[2J\u{001B}[H", terminator: "")
    fflush(stdout)
}

@inline(__always)
func hideCursor() {
    print("\u{001B}[?25l", terminator: "")
    fflush(stdout)
}

@inline(__always)
func showCursor() {
    print("\u{001B}[?25h", terminator: "")
    fflush(stdout)
}

@inline(__always)
func readByte() -> UInt8? {
    var b: UInt8 = 0
    let n = read(STDIN_FILENO_, &b, 1)
    return (n == 1) ? b : nil
}

/// Non-blocking key decoder.
/// Handles printable chars, Enter, Backspace, Tab, Ctrl-C, Escape, Arrow keys (ESC [ A/B/C/D).
func readKeyEvent() -> KeyEvent? {
    guard let first = readByte() else { return nil }

    switch first {
    case 0x03: return .ctrlC              // ^C
    case 0x09: return .tab                // Tab
    case 0x0A, 0x0D: return .enter       // LF/CR
    case 0x7F: return .backspace         // Backspace (DEL)

    case 0x1B: // ESC or start of sequence
        // Attempt to read two more bytes for common CSI sequences.
        // Tiny coalescing delay to allow non-blocking reads to gather.
        usleep(2000)
        let b1 = readByte()
        let b2 = readByte()

        if b1 == 0x5B { // '['
            switch b2 {
            case 0x41: return .upArrow    // 'A'
            case 0x42: return .downArrow  // 'B'
            case 0x43: return .rightArrow // 'C'
            case 0x44: return .leftArrow  // 'D'
            case 0x5A: return .backTab    // 'Z' (Shift+Tab)
            default: return .escape
            }
        } else {
            return .escape
        }

    default:
        if first >= 0x20 && first <= 0x7E { // printable ASCII
            return .char(Character(UnicodeScalar(first)))
        }
        return nil
    }
}
