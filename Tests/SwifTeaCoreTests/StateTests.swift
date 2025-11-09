import Testing
@testable import SwifTeaCore
@testable import SwifTeaUI

struct StateTests {

    @Test("State changes should update rendered output")
    func testStateUpdatesRerender() {

        struct DummyApp: TUIScene {
            @State var count = 0
            enum Action { case none }

            // Allow test harness to read the whole app as Model
            typealias Model = DummyApp

            func view(model: Model) -> some TUIView {
                Text("Count: \(count)")
            }
            mutating func update(action: Action) {}
            func mapKeyToAction(_ key: KeyEvent) -> Action? { nil }
            func shouldExit(for action: Action) -> Bool { false }
        }

        var app = DummyApp()

        let initial = SwifTea.testRender(app)
        #expect(initial == "Count: 0")

        app.count += 1

        let updated = SwifTea.testRender(app)
        #expect(updated == "Count: 1")
    }
}

extension SwifTea {
        static func testRender<App: TUIScene>(_ app: App) -> String {
                app.view(model: app.model).render()
        }
}

extension TUIScene where Model == Self {
    var model: Self { self }
}
