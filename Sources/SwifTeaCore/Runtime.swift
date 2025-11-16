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

public protocol TUIScene {
    associatedtype Model = Self
    associatedtype Action = Never
    associatedtype Content: TUIView

    // Default model access: the whole app is the model
    var model: Model { get }

    // UI declaration
    func view(model: Model) -> Content

    // Optional reducer behavior when actions exist
    mutating func update(action: Action)
    mutating func initializeEffects()
    mutating func handleTerminalResize(from oldSize: TerminalSize, to newSize: TerminalSize)
    func mapKeyToAction(_ key: KeyEvent) -> Action?
    func shouldExit(for action: Action) -> Bool
    mutating func handleFrame(deltaTime: TimeInterval)
}

@resultBuilder
public enum TUISceneBuilder {
    public static func buildBlock<Content: TUIScene>(_ content: Content) -> Content {
        content
    }
}

public extension TUIScene {
    mutating func initializeEffects() {}
    mutating func handleTerminalResize(from oldSize: TerminalSize, to newSize: TerminalSize) {}
    mutating func handleFrame(deltaTime: TimeInterval) {}
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
    case reset        = "\u{001B}[0m"
    case black        = "\u{001B}[30m"
    case red          = "\u{001B}[31m"
    case green        = "\u{001B}[32m"
    case yellow       = "\u{001B}[33m"
    case blue         = "\u{001B}[34m"
    case magenta      = "\u{001B}[35m"
    case cyan         = "\u{001B}[36m"
    case white        = "\u{001B}[37m"
    case brightBlack  = "\u{001B}[90m"
    case brightRed    = "\u{001B}[91m"
    case brightGreen  = "\u{001B}[92m"
    case brightYellow = "\u{001B}[93m"
    case brightBlue   = "\u{001B}[94m"
    case brightMagenta = "\u{001B}[95m"
    case brightCyan   = "\u{001B}[96m"
    case brightWhite  = "\u{001B}[97m"

    public var backgroundCode: String {
        switch self {
        case .reset:
            return ANSIColor.reset.rawValue
        case .black:
            return "\u{001B}[40m"
        case .red:
            return "\u{001B}[41m"
        case .green:
            return "\u{001B}[42m"
        case .yellow:
            return "\u{001B}[43m"
        case .blue:
            return "\u{001B}[44m"
        case .magenta:
            return "\u{001B}[45m"
        case .cyan:
            return "\u{001B}[46m"
        case .white:
            return "\u{001B}[47m"
        case .brightBlack:
            return "\u{001B}[100m"
        case .brightRed:
            return "\u{001B}[101m"
        case .brightGreen:
            return "\u{001B}[102m"
        case .brightYellow:
            return "\u{001B}[103m"
        case .brightBlue:
            return "\u{001B}[104m"
        case .brightMagenta:
            return "\u{001B}[105m"
        case .brightCyan:
            return "\u{001B}[106m"
        case .brightWhite:
            return "\u{001B}[107m"
        }
    }

    public var rgbComponents: (Int, Int, Int) {
        switch self {
        case .reset:
            return (0, 0, 0)
        case .black:
            return (0, 0, 0)
        case .red:
            return (205, 49, 49)
        case .green:
            return (13, 188, 121)
        case .yellow:
            return (229, 229, 16)
        case .blue:
            return (36, 114, 200)
        case .magenta:
            return (188, 63, 188)
        case .cyan:
            return (17, 168, 205)
        case .white:
            return (229, 229, 229)
        case .brightBlack:
            return (102, 102, 102)
        case .brightRed:
            return (241, 76, 76)
        case .brightGreen:
            return (35, 209, 139)
        case .brightYellow:
            return (245, 245, 67)
        case .brightBlue:
            return (59, 142, 234)
        case .brightMagenta:
            return (214, 112, 214)
        case .brightCyan:
            return (41, 184, 219)
        case .brightWhite:
            return (255, 255, 255)
        }
    }
}

// MARK: - Public runtime namespace

public enum SwifTea {
    /// Bubble Tea–style runtime loop. Owns terminal, input routing, rendering.
    public static func brew<App: TUIScene>(_ app: App, fps: Int = 20) {
        var app = app
        let frameDelay = useconds_t(1_000_000 / max(1, fps))

        let actionQueue = ActionQueue<App.Action>()
        let effectRuntime = EffectRuntime(actionQueue: actionQueue)
        let originalMode = setRawMode()
        hideCursor()
        let frameLogger = FrameLogger.make()
        defer {
            showCursor()
            restoreMode(originalMode)
            effectRuntime.cancelAll()
        }
        clearScreenAndHome()
        TerminalDimensions.refresh()
        RuntimeDispatch.install(queue: actionQueue, effectRuntime: effectRuntime) {
            app.initializeEffects()

            var running = true
            var lastFrame: String? = nil
            var staticFrameStreak = 0
            let maxStaticFrames = 5
            var lastSize = TerminalDimensions.current
            var lastTime = ProcessInfo.processInfo.systemUptime

            while running {
                let now = ProcessInfo.processInfo.systemUptime
                let deltaTime = now - lastTime
                lastTime = now
                app.handleFrame(deltaTime: deltaTime)

                let size = TerminalDimensions.refresh()
                let sizeChanged = size != lastSize
                let isDrawable = size.columns > 0 && size.rows > 0
                if sizeChanged {
                    app.handleTerminalResize(from: lastSize, to: size)
                    if isDrawable {
                        clearScreenAndHome()
                    }
                }

                if isDrawable {
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
                } else {
                    lastFrame = nil
                    staticFrameStreak = 0
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

                // Async effects → Action
                if running {
                    let pendingActions = actionQueue.drain()
                    if !pendingActions.isEmpty {
                        for action in pendingActions {
                            if app.shouldExit(for: action) {
                                running = false
                                break
                            }
                            app.update(action: action)
                        }
                    }
                }

                usleep(frameDelay)
            }
        }
    }

    public static func dispatch<Action>(_ action: Action) {
        RuntimeDispatch.dispatch(action: action)
    }

    public static func dispatch<Action>(
        _ effect: Effect<Action>,
        id: AnyHashable? = nil,
        cancelExisting: Bool = false
    ) {
        RuntimeDispatch.dispatch(effect: effect, id: id, cancelExisting: cancelExisting)
    }

    public static func cancelEffects(withID id: AnyHashable) {
        RuntimeDispatch.cancel(id: id)
    }
}

// MARK: - Runtime effect plumbing

private final class ActionQueue<Action> {
    private var buffer: [Action] = []
    private let lock = NSLock()

    func enqueue(_ action: Action) {
        lock.lock()
        buffer.append(action)
        lock.unlock()
    }

    func drain() -> [Action] {
        lock.lock()
        let actions = buffer
        buffer.removeAll(keepingCapacity: true)
        lock.unlock()
        return actions
    }
}

private final class EffectRuntime<Action> {
    private let actionQueue: ActionQueue<Action>
    private let lock = NSLock()
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var keyedTasks: [AnyHashable: Set<UUID>] = [:]

    init(actionQueue: ActionQueue<Action>) {
        self.actionQueue = actionQueue
    }

    func run(_ effect: Effect<Action>, id: AnyHashable?, cancelExisting: Bool) {
        if cancelExisting, let id {
            cancel(id)
        }

        let effectID = UUID()
        let task = Task(priority: effect.taskPriority) { [weak self] in
            guard let self else { return }
            await effect.run { [weak self] action in
                self?.actionQueue.enqueue(action)
            }
        }

        lock.lock()
        tasks[effectID] = task
        if let id {
            var set = keyedTasks[id, default: []]
            set.insert(effectID)
            keyedTasks[id] = set
        }
        lock.unlock()

        Task.detached(priority: .background) { [weak self] in
            _ = await task.result
            self?.remove(effectID, keyedBy: id)
        }
    }

    func cancel(_ id: AnyHashable) {
        lock.lock()
        guard let uuids = keyedTasks.removeValue(forKey: id) else {
            lock.unlock()
            return
        }
        let tasksToCancel = uuids.compactMap { tasks.removeValue(forKey: $0) }
        lock.unlock()
        for task in tasksToCancel {
            task.cancel()
        }
    }

    func cancelAll() {
        lock.lock()
        let runningTasks = Array(tasks.values)
        tasks.removeAll()
        keyedTasks.removeAll()
        lock.unlock()
        for task in runningTasks {
            task.cancel()
        }
    }

    private func remove(_ uuid: UUID, keyedBy id: AnyHashable?) {
        lock.lock()
        tasks.removeValue(forKey: uuid)
        if let id {
            var set = keyedTasks[id] ?? []
            set.remove(uuid)
            if set.isEmpty {
                keyedTasks.removeValue(forKey: id)
            } else {
                keyedTasks[id] = set
            }
        }
        lock.unlock()
    }
}

private struct RuntimeDispatchBox {
    let sendAction: (Any) -> Void
    let runEffect: (Any, AnyHashable?, Bool) -> Void
    let cancelEffects: (AnyHashable) -> Void
}

private enum RuntimeDispatch {
    private static let lock = NSLock()
    private static var box: RuntimeDispatchBox?

    static func install<Action>(
        queue: ActionQueue<Action>,
        effectRuntime: EffectRuntime<Action>,
        body: () -> Void
    ) {
        lock.lock()
        box = RuntimeDispatchBox(
            sendAction: { anyAction in
                guard let action = anyAction as? Action else {
                    assertionFailure("Dispatched action does not match active scene Action type.")
                    return
                }
                queue.enqueue(action)
            },
            runEffect: { anyEffect, id, cancelExisting in
                guard let effect = anyEffect as? Effect<Action> else {
                    assertionFailure("Dispatched effect does not match active scene Action type.")
                    return
                }
                effectRuntime.run(effect, id: id, cancelExisting: cancelExisting)
            },
            cancelEffects: { id in
                effectRuntime.cancel(id)
            }
        )
        lock.unlock()

        body()

        lock.lock()
        box = nil
        lock.unlock()
    }

    static func dispatch<Action>(action: Action) {
        lock.lock()
        let current = box
        lock.unlock()
        guard let current else { return }
        current.sendAction(action)
    }

    static func dispatch<Action>(effect: Effect<Action>, id: AnyHashable?, cancelExisting: Bool) {
        lock.lock()
        let current = box
        lock.unlock()
        guard let current else { return }
        current.runEffect(effect, id, cancelExisting)
    }

    static func cancel(id: AnyHashable) {
        lock.lock()
        let current = box
        lock.unlock()
        current?.cancelEffects(id)
    }
}

// MARK: - Declarative app entry point

/// SwiftUI-like entry wrapper that boots the runtime automatically.
public protocol TUIApp {
    associatedtype Body: TUIScene
    init()
    static var framesPerSecond: Int { get }
    @TUISceneBuilder var body: Body { get }
}

public extension TUIApp where Body == Self, Self: TUIScene {
    var body: Self { self }
}

public extension TUIApp {
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
                    result.append(ANSIColor.reset.rawValue)
                    result.append(String(repeating: " ", count: width - currentWidth))
                }
                result.append(character)
                currentWidth = 0
                inEscape = false
                continue
            }

            if character == "\u{001B}" {
                inEscape = true
            } else if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
            } else {
                currentWidth += 1
            }

            result.append(character)
        }

        if currentWidth < width {
            result.append(ANSIColor.reset.rawValue)
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
