import SwifTeaUI

public struct HelloWorldPreviewProvider: TUIViewPreviewProvider {
    public static var previews: [TUIViewPreview] {
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

        TUIViewPreview(
            "Rich Text",
            category: "Samples",
            size: TerminalSize(columns: 52, rows: 10)
        ) {
            RichTextPreviewView()
        }
    }
}

private struct RichTextPreviewView: TUIView {
    var body: some TUIView {
        Border(
            padding: 1,
            color: .brightMagenta,
            HStack(spacing: 2) {
                Text("Rules").foregroundColor(.brightMagenta).bold()
                RichText {
                    InlineGroup {
                        TextSpan("").foregroundColor(.brightYellow)
                        TextSpan("Attack")
                            .foregroundColor(.black)
                            .backgroundColor(.brightYellow)
                            .bold()
                        TextSpan("").foregroundColor(.brightYellow)
                    }
                    TextSpan(" Draw one card, then discard one card. Styled text wraps as one paragraph.")
                }
                .frame(width: .flexible(minimum: 24))
            }
        )
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

    enum Action: Sendable {
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
