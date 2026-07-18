import Foundation
import SwifTeaUI

@main
enum LifecycleFixture {
    static func main() {
        let sessionCount = ProcessInfo.processInfo.environment["SWIFTEA_LIFECYCLE_SESSIONS"] == "2" ? 2 : 1
        for session in 1...sessionCount {
            SwifTea.brew(
                LifecycleScene(session: session),
                fps: 60,
                inputOptions: TerminalInputOptions(bracketedPaste: true)
            )
        }
    }
}

private struct LifecycleScene: TUIScene {
    enum Action: Sendable {
        case quit
    }

    struct Model {
        let session: Int
    }

    let model: Model

    init(session: Int) {
        model = Model(session: session)
    }

    func view(model: Model) -> some TUIView {
        let size = TerminalDimensions.current
        if ProcessInfo.processInfo.environment["SWIFTEA_LITERAL_PAYLOAD"] == "1" {
            return Text(
                "Lifecycle fixture ready session=\(model.session) size=\(size.columns)x\(size.rows)\n"
                    + "Literal payload \u{001B}[2J\u{001B}[38;5;196m\u{001B}]0;swiftea-injection\u{0007}"
            )
        }
        return Text("Lifecycle fixture ready session=\(model.session) size=\(size.columns)x\(size.rows)")
    }

    mutating func update(action: Action) {}

    mutating func initializeEffects() {
        guard ProcessInfo.processInfo.environment["SWIFTEA_LIFECYCLE_THROW"] == "1" else {
            return
        }
        SwifTea.dispatch(
            Effect<Action>.run { _ in
                throw FixtureError.expected
            },
            id: "expected-failure"
        )
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("q"), .ctrlC:
            return .quit
        default:
            return nil
        }
    }

    func mapInputToAction(_ input: TerminalInputEvent) -> Action? {
        switch input {
        case .key(let key): mapKeyToAction(key)
        case .paste("quit"): .quit
        case .paste: nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        true
    }

    private enum FixtureError: Error {
        case expected
    }
}
