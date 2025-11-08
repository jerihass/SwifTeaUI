import SwifTeaCore
import SwifTeaUI

@main
struct NotebookApp: SwifTeaApp {
    static var framesPerSecond: Int { 120 }
    var body: some SwifTeaScene { NotebookScene() }
}

struct NotebookScene: SwifTeaScene {
    enum Action {
        case selectNext
        case selectPrevious
        case focusNext
        case focusPrevious
        case setFocus(NotebookFocusField?)
        case editTitle(TextFieldEvent)
        case editBody(TextFieldEvent)
        case quit
    }

    @State private var state = NotebookState()
    private let viewModel = NotebookViewModel()
    private let focusCoordinator = NotebookFocusCoordinator()
    @FocusState private var focusedField: NotebookFocusField? = .sidebar

    var model: NotebookScene { self }

    mutating func update(action: Action) {
        switch action {
        case .selectNext:
            viewModel.selectNext(state: &state)
        case .selectPrevious:
            viewModel.selectPrevious(state: &state)
        case .focusNext:
            focusCoordinator.focusNext(current: &focusedField)
        case .focusPrevious:
            focusCoordinator.focusPrevious(current: &focusedField)
        case .setFocus(let target):
            focusedField = target
        case .editTitle(let event):
            if let effect = viewModel.handleTitle(event: event, state: &state) {
                apply(effect)
            }
        case .editBody(let event):
            if let effect = viewModel.handleBody(event: event, state: &state) {
                apply(effect)
            }
        case .quit:
            break
        }
    }

    func view(model: NotebookScene) -> some TUIView {
        NotebookView(
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
        case .upArrow:
            return focusedField == .sidebar ? .selectPrevious : nil
        case .downArrow:
            return focusedField == .sidebar ? .selectNext : nil
        case .enter:
            if focusedField == .sidebar {
                return .setFocus(.editorTitle)
            }
        case .char("q"), .char("Q"):
            let canQuit = (focusedField == .sidebar || focusedField == nil)
            if canQuit {
                return .quit
            }
        case .ctrlC:
            return .quit
        default:
            break
        }

        if let event = textFieldEvent(from: key) {
            switch focusedField {
            case .editorTitle:
                return .editTitle(event)
            case .editorBody:
                return .editBody(event)
            default:
                break
            }
        }

        return nil
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action { return true }
        return false
    }

    private mutating func apply(_ effect: NotebookViewModel.Effect) {
        switch effect {
        case .focus(let field):
            focusedField = field
        }
    }

    private var titleBinding: Binding<String> {
        $state.map(\.editorTitle)
    }

    private var bodyBinding: Binding<String> {
        $state.map(\.editorBody)
    }

    private var titleFocusBinding: Binding<Bool> {
        $focusedField.isFocused(.editorTitle)
    }

    private var bodyFocusBinding: Binding<Bool> {
        $focusedField.isFocused(.editorBody)
    }
}
