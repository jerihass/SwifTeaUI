import SwifTeaUI

struct HelloWorldPreviewProvider: TUIViewPreviewProvider {
    static var previews: [TUIViewPreview] {
        TUIViewPreview(
            "Hello World",
            category: "Samples",
            size: TerminalSize(columns: 40, rows: 6)
        ) {
            HelloWorldPreviewView(message: "Hello, SwifTeaUI!")
        }

        TUIViewPreview.scene(
            "Counter Demo",
            category: "Samples",
            size: TerminalSize(columns: 40, rows: 8)
        ) {
            CounterDemoScene(model: .init(title: "Counter", count: 42))
        }
    }
}

private struct HelloWorldPreviewView: TUIView {
    var message: String

    var body: some TUIView {
        Border(
            padding: 1,
            color: .brightMagenta,
            background: .brightBlack,
            VStack(spacing: 1, alignment: .leading) {
                Text("Preview Builder")
                    .foregroundColor(.brightMagenta)
                    .bold()
                Text(message)
                    .foregroundColor(.brightWhite)
                Text("Customize terminal size + theme.")
                    .foregroundColor(.brightCyan)
            }
        )
    }
}

private struct CounterDemoScene: TUIScene {
    struct Model {
        var title: String
        var count: Int
    }

    enum Action {
        case increment
    }

    var model: Model

    mutating func update(action: Action) {
        switch action {
        case .increment:
            model.count += 1
        }
    }

    func view(model: Model) -> some TUIView {
        Border(
            padding: 1,
            color: .brightGreen,
            background: .brightBlack,
            VStack(spacing: 1, alignment: .leading) {
                Text(model.title)
                    .foregroundColor(.brightGreen)
                    .bold()
                Text("Counter: \(model.count)")
                    .foregroundColor(.brightWhite)
                Text("Tap space to increment (runtime only).")
                    .foregroundColor(.brightYellow)
            }
        )
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        if case .char(" ") = key {
            return .increment
        }
        return nil
    }

    func shouldExit(for action: Action) -> Bool {
        false
    }
}
