import SwifTeaCore
import SwifTeaUI

@main
struct TaskRunnerApp: SwifTeaApp {
    var body: some SwifTeaScene { self }
    enum Action {
        case advance
        case fail
        case reset
        case quit
    }

    @State private var state = TaskRunnerState()
    private let viewModel = TaskRunnerViewModel()

    var model: TaskRunnerApp { self }

    mutating func update(action: Action) {
        state.tickToasts()

        switch action {
        case .advance:
            viewModel.advance(state: &state)
        case .fail:
            viewModel.markFailure(state: &state)
        case .reset:
            viewModel.reset(state: &state)
        case .quit:
            break
        }
    }

    func view(model: TaskRunnerApp) -> some TUIView {
        TaskRunnerView(state: model.state)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .enter, .char(" "):
            return .advance
        case .char("f"), .char("F"):
            return .fail
        case .char("r"), .char("R"):
            return .reset
        case .char("q"), .char("Q"), .ctrlC, .escape:
            return .quit
        default:
            return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action {
            return true
        }
        return false
    }
}
