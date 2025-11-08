import Foundation

// MARK: - Core UI protocols

public protocol TUIView {
    associatedtype Body: TUIView
    var body: Body { get }
    func render() -> String
}

public extension TUIView {
    func render() -> String {
        body.render()
    }
}

extension Never: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public func render() -> String {
        fatalError("Never cannot render")
    }
}

public protocol TUIApp {
    associatedtype Model = Self
    associatedtype Action = Never
    associatedtype Content: TUIView

    // Default model access: the whole app is the model
    var model: Model { get }

    // UI declaration
    func view(model: Model) -> Content

    // Optional reducer behavior when actions exist
    mutating func update(action: Action)
    func mapKeyToAction(_ key: KeyEvent) -> Action?
    func shouldExit(for action: Action) -> Bool
}

public protocol SwifTeaScene: TUIApp {}

@resultBuilder
public enum SwifTeaSceneBuilder {
    public static func buildBlock<Content: SwifTeaScene>(_ content: Content) -> Content {
        content
    }
}

// MARK: - ANSI helpers & color

public enum ANSI {
    public static let esc = "\u{001B}"
    public static let clear = "\(esc)[2J"
    public static let home  = "\(esc)[H"
    public static func color(_ code: Int) -> String { "\(esc)[\(code)m" }
    public static let reset = color(0)
}

public enum ANSIColor: String {
    case reset  = "\u{001B}[0m"
    case green  = "\u{001B}[32m"
    case cyan   = "\u{001B}[36m"
    case yellow = "\u{001B}[33m"
}

// MARK: - Public runtime namespace

public enum SwifTea {
    /// Bubble Tea–style runtime loop. Owns terminal, input routing, rendering.
    public static func brew<App: TUIApp>(_ app: App, fps: Int = 20) {
        var app = app
        let frameDelay = useconds_t(1_000_000 / max(1, fps))

        let originalMode = setRawMode()
        hideCursor()
        let frameLogger = FrameLogger.make()
        defer {
            showCursor()
            restoreMode(originalMode)
        }
        clearScreenAndHome()
        TerminalDimensions.refresh()
        var running = true
        var lastFrame: String? = nil
        var staticFrameStreak = 0
        let maxStaticFrames = 5
        var lastSize = TerminalDimensions.current
        while running {
            let size = TerminalDimensions.refresh()
            let sizeChanged = size != lastSize
            if sizeChanged {
                clearScreenAndHome()
            }
            // Render
            let frame = app.view(model: app.model).render()
            let changed = frame != lastFrame
            let forceRefresh = sizeChanged || (!changed ? (staticFrameStreak >= maxStaticFrames) : false)
            frameLogger?.log(frame, changed: changed, forced: forceRefresh)
            if changed || forceRefresh {
                renderFrame(frame)
                lastFrame = frame
                staticFrameStreak = 0
            } else {
                staticFrameStreak += 1
            }
            lastSize = size

            // Input → Action
            if let ke = readKeyEvent(), let action = app.mapKeyToAction(ke) {
                if app.shouldExit(for: action) {
                    running = false
                } else {
                    app.update(action: action)
                }
            }

            // (Future) timers/async effects enqueue actions here

            usleep(frameDelay)
        }
    }
}

// MARK: - Declarative app entry point

/// SwiftUI-like entry wrapper that boots the runtime automatically.
public protocol SwifTeaApp: SwifTeaScene {
    associatedtype Body: SwifTeaScene
    init()
    static var framesPerSecond: Int { get }
    @SwifTeaSceneBuilder var body: Body { get }
}

public extension SwifTeaApp where Body == Self {
    var body: Self { self }
}

public extension SwifTeaApp {
    static var framesPerSecond: Int { 20 }

    static func main() {
        SwifTea.brew(Self.init().body, fps: framesPerSecond)
    }
}

private final class FrameLogger {
    private let handle: FileHandle
    private var frameIndex: Int = 0

    private init?(path: String) {
        let manager = FileManager.default
        if manager.fileExists(atPath: path) {
            try? manager.removeItem(atPath: path)
        }

        manager.createFile(atPath: path, contents: nil, attributes: nil)

        guard let handle = FileHandle(forWritingAtPath: path) else {
            return nil
        }

        self.handle = handle
    }

    deinit {
        try? handle.close()
    }

    static func make() -> FrameLogger? {
        guard let path = ProcessInfo.processInfo.environment["SWIFTEA_FRAME_LOG"],
              !path.isEmpty else { return nil }
        return FrameLogger(path: path)
    }

    func log(_ frame: String, changed: Bool, forced: Bool) {
        frameIndex += 1
        let header = "\n--- frame \(frameIndex) (changed: \(changed) forced: \(forced)) ---\n"
        guard let headerData = header.data(using: .utf8),
              let frameData = frame.data(using: .utf8),
              let newline = "\n".data(using: .utf8) else { return }

        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: headerData)
            try handle.write(contentsOf: frameData)
            try handle.write(contentsOf: newline)
        } catch {
            // Best-effort logging; ignore write failures.
        }
    }
}

@inline(__always)
private func moveCursorHome() {
    writeToStdout("\u{001B}[H")
}

@inline(__always)
private func clearBelowCursor() {
    writeToStdout("\u{001B}[J")
}

@inline(__always)
private func renderFrame(_ frame: String) {
    moveCursorHome()
    let columns = TerminalDimensions.current.columns
    if columns > 0 {
        writeToStdout(frame.padded(toVisibleWidth: columns))
    } else {
        writeToStdout(frame)
    }
    clearBelowCursor()
    fflush(stdout)
}

@inline(__always)
private func writeToStdout(_ string: String) {
    guard !string.isEmpty, let data = string.data(using: .utf8) else { return }
    try? FileHandle.standardOutput.write(contentsOf: data)
}

extension String {
    func padded(toVisibleWidth width: Int) -> String {
        guard width > 0 else { return self }

        var result = String()
        result.reserveCapacity(count + width)

        var currentWidth = 0
        var inEscape = false

        for character in self {
            if character == "\n" {
                if currentWidth < width {
                    result.append(String(repeating: " ", count: width - currentWidth))
                }
                result.append(character)
                currentWidth = 0
                inEscape = false
                continue
            }

            result.append(character)

            if character == "\u{001B}" {
                inEscape = true
            } else if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
            } else {
                currentWidth += 1
            }
        }

        if currentWidth < width {
            result.append(String(repeating: " ", count: width - currentWidth))
        }

        return result
    }
}

extension Character {
    var isANSISequenceTerminator: Bool {
        switch self {
        case "a"..."z", "A"..."Z":
            return true
        default:
            return false
        }
    }
}
