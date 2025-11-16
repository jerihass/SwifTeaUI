import SwifTeaCore
import SwifTeaUI

public struct ShowcaseApp: TUIApp {
    public init() {}
    public var body: some TUIScene { ShowcaseScene() }
}

struct ShowcaseScene: TUIScene {
    typealias Model = ShowcaseModel
    typealias Action = ShowcaseModel.Action

    var model: ShowcaseModel

    init(model: ShowcaseModel = ShowcaseModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: ShowcaseModel) -> some TUIView {
        model.makeView()
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        model.mapKeyToAction(key)
    }

    func shouldExit(for action: Action) -> Bool {
        model.shouldExit(for: action)
    }
}

struct ShowcaseModel {
    enum Action {
        case increment
        case decrement
        case quit
    }

    @State private var count: Int

    init(count: Int = 0) {
        self._count = State(wrappedValue: count)
    }

    mutating func update(action: Action) {
        switch action {
        case .increment:
            count += 1
        case .decrement:
            count -= 1
        case .quit:
            break
        }
    }

    func makeView() -> some TUIView {
        ShowcaseView(count: count)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("u"), .rightArrow: return .increment
        case .char("d"), .leftArrow: return .decrement
        case .char("q"), .escape, .ctrlC: return .quit
        default: return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action { return true }
        return false
    }
}

struct ShowcaseView: TUIView {
    let count: Int

    var body: some TUIView {
        MinimumTerminalSize(columns: 60, rows: 20) {
            Border(
                padding: 1,
                color: .brightMagenta,
                VStack(spacing: 2, alignment: .leading) {
                    Text("SwifTea Showcase")
                        .foregroundColor(.brightYellow)
                        .bold()
                    colorSection
                    borderSection
                    counterSection
                }
            )
        } fallback: { size in
            VStack(spacing: 1, alignment: .leading) {
                Text("Need at least 60×20 characters.")
                    .foregroundColor(.brightYellow)
                Text("Current size: \(size.columns)×\(size.rows)")
                    .foregroundColor(.brightCyan)
            }
            .padding(1)
        }
    }

    private var colorSection: some TUIView {
        Border(
            padding: 1,
            color: .brightBlue,
            VStack(alignment: .leading) {
                Text("Color Demo")
                    .foregroundColor(.brightWhite)
                    .bold()
                Text("Foreground + background sample text")
                    .foregroundColor(.brightWhite)
                    .backgroundColor(.blue)
            }
        )
    }

    private var borderSection: some TUIView {
        let inner = Border(
            padding: 0,
            color: .brightYellow,
            background: .brightBlack,
            VStack(spacing: 0) {
                Text("Inner Border")
                    .foregroundColor(.brightWhite)
                    .backgroundColor(.brightBlue)
                    .bold()
                Text("Nested borders keep their own colors.")
                    .foregroundColor(.brightCyan)
            }
        )

        return Border(
            padding: 1,
            color: .brightBlue,
            background: .blue,
            VStack(spacing: 1, alignment: .leading) {
                Text("Border Demo")
                    .foregroundColor(.brightWhite)
                    .bold()
                inner
            }
        )
    }

    private var counterSection: some TUIView {
        Border(
            padding: 1,
            color: .brightGreen,
            VStack(spacing: 1, alignment: .leading) {
                Text("Counter Demo")
                    .foregroundColor(.brightWhite)
                    .bold()
                Text("Count: \(count)")
                    .foregroundColor(.brightGreen)
                Text("[←/u] increment | [→/d] decrement")
                    .foregroundColor(.brightCyan)
                Text("[q]/[Esc]/[Ctrl-C] quits")
                    .foregroundColor(.brightBlue)
            }
        )
    }
}
