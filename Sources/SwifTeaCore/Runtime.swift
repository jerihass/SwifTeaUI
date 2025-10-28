import Foundation

// MARK: - Core UI protocols

public protocol TUIView {
    func render() -> String
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
        defer { restoreMode(originalMode) }

        var running = true
        while running {
            // Render
            clearScreenAndHome()
            print(app.view(model: app.model).render())

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

