import Dispatch
import Foundation

#if os(Linux)
    import Glibc
    private let STDIN_FILENO_: Int32 = 0
    private let STDOUT_FILENO_: Int32 = 1
#else
    import Darwin
    private let STDIN_FILENO_: Int32 = STDIN_FILENO
    private let STDOUT_FILENO_: Int32 = STDOUT_FILENO
#endif

private typealias TerminalSignalHandler = @convention(c) (Int32) -> Void

public struct TerminalSize: Equatable, Sendable {
    public var columns: Int
    public var rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = max(0, columns)
        self.rows = max(0, rows)
    }

    public static let zero = TerminalSize(columns: 0, rows: 0)
}

private final class TerminalDimensionsState: @unchecked Sendable {
    let lock = NSRecursiveLock()
    var currentSize = TerminalSize(columns: 80, rows: 24)
    var overrideStack: [TerminalSize] = []
    var needsRefresh = true
}

public enum TerminalDimensions {
    private static let state = TerminalDimensionsState()

    public static var current: TerminalSize {
        state.lock.lock()
        let value = state.overrideStack.last ?? state.currentSize
        state.lock.unlock()
        return value
    }

    @discardableResult
    public static func refresh() -> TerminalSize {
        state.lock.lock()
        if let override = state.overrideStack.last {
            state.needsRefresh = false
            state.lock.unlock()
            return override
        }
        let shouldQuery = state.needsRefresh
        let cached = state.currentSize
        state.lock.unlock()

        guard shouldQuery else { return cached }

        let queried = queryTerminalSize() ?? cached
        state.lock.lock()
        state.currentSize = queried
        state.needsRefresh = false
        state.lock.unlock()
        return queried
    }

    public static func withTemporarySize<T>(
        _ size: TerminalSize,
        _ perform: () throws -> T
    ) rethrows -> T {
        state.lock.lock()
        state.overrideStack.append(size)
        defer {
            state.overrideStack.removeLast()
            if state.overrideStack.isEmpty {
                state.needsRefresh = true
            }
            state.lock.unlock()
        }
        return try perform()
    }

    private static func queryTerminalSize() -> TerminalSize? {
        var ws = winsize()
        if ioctl(STDIN_FILENO_, UInt(TIOCGWINSZ), &ws) == 0 {
            return TerminalSize(columns: Int(ws.ws_col), rows: Int(ws.ws_row))
        }
        return nil
    }

    static func markNeedsRefresh() {
        state.lock.lock()
        if state.overrideStack.isEmpty {
            state.needsRefresh = true
        }
        state.lock.unlock()
    }
}

struct TerminalState {
    var attributes: termios?
    var fileStatusFlags: Int32?
}

@discardableResult
func setRawMode() -> TerminalState {
    let flags = fcntl(STDIN_FILENO_, F_GETFL)
    var state = TerminalState(
        attributes: nil,
        fileStatusFlags: flags == -1 ? nil : flags
    )

    var t = termios()
    guard tcgetattr(STDIN_FILENO_, &t) == 0 else {
        let message = String(cString: strerror(errno))
        writeToStderr("Warning: unable to read terminal settings: \(message)\n")
        return state
    }
    state.attributes = t

    // Preserve signal bytes as key input so applications can handle Ctrl-C as a KeyEvent.
    t.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG)

    guard tcsetattr(STDIN_FILENO_, TCSANOW, &t) == 0 else {
        let message = String(cString: strerror(errno))
        writeToStderr("Warning: unable to set raw mode: \(message)\n")
        return state
    }

    if let originalFlags = state.fileStatusFlags {
        _ = fcntl(STDIN_FILENO_, F_SETFL, originalFlags | O_NONBLOCK)
    }
    return state
}

func restoreMode(_ state: TerminalState) {
    if var attributes = state.attributes {
        _ = tcflush(STDIN_FILENO_, TCIFLUSH)
        _ = tcsetattr(STDIN_FILENO_, TCSANOW, &attributes)
    }
    if let flags = state.fileStatusFlags {
        _ = fcntl(STDIN_FILENO_, F_SETFL, flags)
    }
}

private final class SignalRegistration: @unchecked Sendable {
    private let signalNumber: Int32
    private let previousHandler: TerminalSignalHandler?
    private let source: DispatchSourceSignal
    private let lock = NSLock()
    private var isRestored = false

    init(
        signal signalNumber: Int32,
        queue: DispatchQueue,
        handler: @escaping @Sendable () -> Void
    ) {
        self.signalNumber = signalNumber
        previousHandler = signal(signalNumber, SIG_IGN)
        source = DispatchSource.makeSignalSource(signal: signalNumber, queue: queue)
        source.setEventHandler(handler: handler)
        source.resume()
    }

    func restore() {
        lock.lock()
        guard !isRestored else {
            lock.unlock()
            return
        }
        isRestored = true
        source.setEventHandler {}
        source.cancel()
        _ = signal(signalNumber, previousHandler)
        lock.unlock()
    }

    deinit {
        restore()
    }
}

private final class TerminationSignalMonitor: @unchecked Sendable {
    private let lock = NSLock()
    private var pendingSignal: Int32?
    private var registrations: [SignalRegistration] = []

    init(
        signals: [Int32] = [SIGINT, SIGTERM, SIGHUP, SIGQUIT],
        queue: DispatchQueue = DispatchQueue(label: "dev.swifteaui.termination-signals")
    ) {
        registrations = signals.map { signalNumber in
            SignalRegistration(signal: signalNumber, queue: queue) { [weak self] in
                self?.record(signalNumber)
            }
        }
    }

    var signal: Int32? {
        lock.lock()
        let value = pendingSignal
        lock.unlock()
        return value
    }

    func restore() {
        let current = registrations
        registrations.removeAll()
        for registration in current {
            registration.restore()
        }
    }

    private func record(_ signalNumber: Int32) {
        lock.lock()
        if pendingSignal == nil {
            pendingSignal = signalNumber
        }
        lock.unlock()
    }
}

final class TerminalSession {
    private let terminationMonitor: TerminationSignalMonitor
    private let resizeRegistration: SignalRegistration
    private let state: TerminalState
    private let managesCursor: Bool
    private let lock = NSLock()
    private var isRestored = false

    init() {
        terminationMonitor = TerminationSignalMonitor()
        resizeRegistration = SignalRegistration(
            signal: SIGWINCH,
            queue: DispatchQueue.global(qos: .userInteractive)
        ) {
            TerminalDimensions.markNeedsRefresh()
            SwifTea.requestRender()
        }
        state = setRawMode()
        managesCursor = isatty(STDOUT_FILENO_) == 1
        if managesCursor {
            hideCursor()
        }
    }

    var pendingTerminationSignal: Int32? {
        terminationMonitor.signal
    }

    func restore() {
        lock.lock()
        guard !isRestored else {
            lock.unlock()
            return
        }
        isRestored = true
        lock.unlock()

        if managesCursor {
            showCursor()
        }
        restoreMode(state)
        resizeRegistration.restore()
        terminationMonitor.restore()
    }

    deinit {
        restore()
    }
}

@inline(__always)
func clearScreenAndHome() {
    // ESC[2J = clear screen; ESC[H = cursor home
    writeToStdout("\u{001B}[2J\u{001B}[H")
}

@inline(__always)
func hideCursor() {
    writeToStdout("\u{001B}[?25l")
}

@inline(__always)
func showCursor() {
    writeToStdout("\u{001B}[?25h")
}

private func writeToStderr(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    try? FileHandle.standardError.write(contentsOf: data)
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
    case 0x03: return .ctrlC  // ^C
    case 0x09: return .tab  // Tab
    case 0x0A, 0x0D: return .enter  // LF/CR
    case 0x7F: return .backspace  // Backspace (DEL)

    case 0x1B:  // ESC or start of sequence
        // Attempt to read two more bytes for common CSI sequences.
        // Tiny coalescing delay to allow non-blocking reads to gather.
        usleep(2000)
        let b1 = readByte()
        let b2 = readByte()

        if b1 == 0x5B {  // '['
            switch b2 {
            case 0x41: return .upArrow  // 'A'
            case 0x42: return .downArrow  // 'B'
            case 0x43: return .rightArrow  // 'C'
            case 0x44: return .leftArrow  // 'D'
            case 0x5A: return .backTab  // 'Z' (Shift+Tab)
            default: return .escape
            }
        } else {
            return .escape
        }

    default:
        if first >= 0x20 && first <= 0x7E {  // printable ASCII
            return .char(Character(UnicodeScalar(first)))
        }
        return nil
    }
}
