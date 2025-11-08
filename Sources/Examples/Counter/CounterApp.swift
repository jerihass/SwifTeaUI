import SwifTeaCore
import SwifTeaUI

@main
struct CounterApp: SwifTeaApp {
    static var framesPerSecond: Int { 30 }
    var body: some SwifTeaScene { self }

    enum Action {
        case increment
        case decrement
        case quit
        case editTitle(TextFieldEvent)
        case editBody(TextFieldEvent)
        case focusNext
        case focusPrevious
    }

    @State private var state = CounterState()
    private let viewModel = CounterViewModel()
    private let focusCoordinator = CounterFocusCoordinator()
    @FocusState private var focusedField: CounterFocusField? = .controls

    var model: CounterApp { self }

    mutating func update(action: Action) {
        switch action {
        case .increment:
            viewModel.increment(state: &state)
        case .decrement:
            viewModel.decrement(state: &state)
        case .editTitle(let event):
            if let effect = viewModel.handleTitle(event: event, state: &state) {
                apply(effect)
            }
        case .editBody(let event):
            if let effect = viewModel.handleBody(event: event, state: &state) {
                apply(effect)
            }
        case .focusNext:
            focusCoordinator.focusNext(current: &focusedField)
        case .focusPrevious:
            focusCoordinator.focusPrevious(current: &focusedField)
        case .quit:
            break
        }
    }

    func view(model: CounterApp) -> some TUIView {
        CounterView(
            state: model.state,
            focus: model.focusedField,
            titleBinding: model.titleBinding,
            bodyBinding: model.bodyBinding,
            titleFocusBinding: model.titleFocusBinding,
            bodyFocusBinding: model.bodyFocusBinding
        )
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .tab:
            return .focusNext
        case .backTab:
            return .focusPrevious
        default:
            break
        }

        if let textEvent = textFieldEvent(from: key) {
            switch focusedField {
            case .noteTitle:
                return .editTitle(textEvent)
            case .noteBody:
                return .editBody(textEvent)
            default:
                break
            }
        }

        switch key {
        case .char("u"), .rightArrow: return .increment
        case .char("d"), .leftArrow:  return .decrement
        case .char("q"), .ctrlC, .escape: return .quit
        default: return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action { return true }
        return false
    }

    private mutating func apply(_ effect: CounterViewModel.Effect) {
        switch effect {
        case .focus(let field):
            focusedField = field
        }
    }

    private var titleBinding: Binding<String> {
        $state.map(\.noteTitle)
    }

    private var bodyBinding: Binding<String> {
        $state.map(\.noteBody)
    }

    private var titleFocusBinding: Binding<Bool> {
        $focusedField.isFocused(.noteTitle)
    }

    private var bodyFocusBinding: Binding<Bool> {
        $focusedField.isFocused(.noteBody)
    }
}
