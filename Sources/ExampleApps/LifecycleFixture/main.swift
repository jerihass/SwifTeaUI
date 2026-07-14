import Foundation
import SwifTeaUI

@main
enum LifecycleFixture {
    static func main() {
        let sessionCount = ProcessInfo.processInfo.environment["SWIFTEA_LIFECYCLE_SESSIONS"] == "2" ? 2 : 1
        for session in 1...sessionCount {
            SwifTea.brew(LifecycleScene(session: session), fps: 60)
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

    func shouldExit(for action: Action) -> Bool {
        true
    }

    private enum FixtureError: Error {
        case expected
    }
}
