import SwifTeaCore
import SwifTeaUI

@main
struct ColorDemoApp: TUIApp {
    static var framesPerSecond: Int { 10 }
    var body: some TUIScene { ColorDemoScene() }
}

struct ColorDemoScene: TUIScene {
    typealias Model = ColorDemoModel
    enum Action {
        case quit
    }

    var model: ColorDemoModel

    init(model: ColorDemoModel = ColorDemoModel()) {
        self.model = model
    }

    mutating func update(action: Action) {}

    func view(model: ColorDemoModel) -> some TUIView {
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

struct ColorDemoModel {
    let sampleText = "Foreground + background sample text"

    func makeView() -> some TUIView {
        ColorDemoView(sampleText: sampleText)
    }
}

struct ColorDemoView: TUIView {
    let sampleText: String

    var body: some TUIView {
        Text(sampleText)
            .foregroundColor(.brightWhite)
            .backgroundColor(.blue)
    }
}
