import SwifTeaCore
import SwifTeaUI

@main
struct BorderDemoApp: TUIApp {
    static var framesPerSecond: Int { 10 }
    var body: some TUIScene { BorderDemoScene() }
}

struct BorderDemoScene: TUIScene {
    typealias Model = BorderDemoModel
    enum Action {
        case quit
    }

    var model: BorderDemoModel

    init(model: BorderDemoModel = BorderDemoModel()) {
        self.model = model
    }

    mutating func update(action: Action) {}

    func view(model: BorderDemoModel) -> some TUIView {
        model.makeView()
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("q"), .char("Q"), .escape, .ctrlC:
            return .quit
        default:
            return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        action == .quit
    }
}

struct BorderDemoModel {
    func makeView() -> some TUIView {
        BorderDemoView()
    }
}

struct BorderDemoView: TUIView {
    var body: some TUIView {
        Border(
            padding: 1,
            color: .brightMagenta,
            background: .black,
            VStack(spacing: 1, alignment: .leading) {
                Text("Border Color Demo")
                    .foregroundColor(.brightYellow)
                    .backgroundColor(.blue)
                    .bold()
                Text("Inspect the right-hand padding for color bleed.")
                    .foregroundColor(.brightCyan)
                Text("Line 2 - bright green bg")
                    .foregroundColor(.black)
                    .backgroundColor(.brightGreen)
                Text("Line 3 - bright red bg")
                    .foregroundColor(.brightWhite)
                    .backgroundColor(.brightRed)
            }
        )
        .padding(1)
    }
}
