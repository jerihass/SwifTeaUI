import SwifTeaUI

public struct NotebookApp: TUIApp {
    public init() {}
    public static var framesPerSecond: Int { 120 }
    public var body: some TUIScene { NotebookScene() }
}

struct NotebookScene: TUIScene {
    typealias Model = NotebookModel
    typealias Action = NotebookModel.Action

    var model: NotebookModel

    init(model: NotebookModel = NotebookModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: NotebookModel) -> some TUIView {
        model.makeView()
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        self.model.mapKeyToAction(key)
    }

    func shouldExit(for action: Action) -> Bool {
        model.shouldExit(for: action)
    }
}

struct NotebookModel {
    enum Action {
        case selectNext
        case selectPrevious
        case focusNext
        case focusPrevious
        case setFocus(NotebookFocusField?)
        case editTitle(TextFieldEvent)
        case editBody(TextFieldEvent)
        case scrollBody(by: Int)
        case moveBodyCursor(Int)
        case quit
    }

    static let bodyViewport = 10

    @State private var state: NotebookState
    private let viewModel: NotebookViewModel
    private let focusCoordinator: NotebookFocusCoordinator
    @FocusState private var focusedField: NotebookFocusField?
    @State private var bodyScrollOffset: Int
    @State private var bodyContentHeight: Int
    @State private var bodyCursorLine: Int
    @State private var followCursor: Bool

    init(
        state: NotebookState = NotebookState(),
        focusedField: NotebookFocusField? = .sidebar,
        viewModel: NotebookViewModel = NotebookViewModel(),
        focusCoordinator: NotebookFocusCoordinator = NotebookFocusCoordinator(),
        bodyScrollOffset: Int = 0,
        bodyContentHeight: Int = 0,
        bodyCursorLine: Int = 0,
        followCursor: Bool = true
    ) {
        self._state = State(wrappedValue: state)
        self._focusedField = FocusState(wrappedValue: focusedField)
        self.viewModel = viewModel
        self.focusCoordinator = focusCoordinator
        self._bodyScrollOffset = State(wrappedValue: bodyScrollOffset)
        self._bodyContentHeight = State(wrappedValue: bodyContentHeight)
        self._bodyCursorLine = State(wrappedValue: bodyCursorLine)
        self._followCursor = State(wrappedValue: followCursor)
    }

    mutating func update(action: Action) {
        switch action {
        case .selectNext:
            viewModel.selectNext(state: &state)
            bodyScrollOffset = 0
            followCursor = true
        case .selectPrevious:
            viewModel.selectPrevious(state: &state)
            bodyScrollOffset = 0
            followCursor = true
        case .focusNext:
            focusCoordinator.focusNext(current: &focusedField)
        case .focusPrevious:
            focusCoordinator.focusPrevious(current: &focusedField)
        case .setFocus(let target):
            focusedField = target
            if target == .editorBody {
                followCursor = true
            }
        case .editTitle(let event):
            if let effect = viewModel.handleTitle(event: event, state: &state) {
                apply(effect)
            }
        case .editBody(let event):
            if let effect = viewModel.handleBody(event: event, state: &state) {
                apply(effect)
            }
            followCursor = true
        case .scrollBody(let delta):
            followCursor = false
            let maxOffset = bodyMaxOffset
            let desired = bodyScrollOffset + delta
            let clamped = max(0, min(desired, maxOffset))
            bodyScrollOffset = clamped
        case .moveBodyCursor(let delta):
            moveCursor(by: delta)
            followCursor = true
        case .quit:
            break
        }
    }

    func makeView() -> some TUIView {
        NotebookView(
            state: state,
            focus: focusedField,
            titleBinding: titleBinding,
            bodyBinding: bodyBinding,
            titleFocusBinding: titleFocusBinding,
            bodyFocusBinding: bodyFocusBinding,
            bodyScrollBinding: bodyScrollBinding,
            bodyContentHeightBinding: bodyContentHeightBinding,
            bodyCursorBinding: bodyCursorBinding,
            bodyCursorLineBinding: bodyCursorLineBinding,
            followCursorBinding: followCursorBinding
        )
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .tab:
            return .focusNext
        case .backTab:
            return .focusPrevious
        case .upArrow:
            if focusedField == .sidebar {
                return .selectPrevious
            } else if focusedField == .editorBody {
                return .scrollBody(by: -1)
            }
            return nil
        case .downArrow:
            if focusedField == .sidebar {
                return .selectNext
            } else if focusedField == .editorBody {
                return .scrollBody(by: 1)
            }
            return nil
        case .leftArrow:
            if focusedField == .editorBody {
                return .moveBodyCursor(-1)
            }
            return nil
        case .rightArrow:
            if focusedField == .editorBody {
                return .moveBodyCursor(1)
            }
            return nil
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

    var allowsSectionShortcuts: Bool {
        focusedField == .sidebar || focusedField == nil
    }

    private mutating func apply(_ effect: NotebookViewModel.Effect) {
        switch effect {
        case .focus(let field):
            focusedField = field
            if field == .editorBody {
                followCursor = true
            }
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

    private var bodyScrollBinding: Binding<Int> {
        $bodyScrollOffset
    }

    private var bodyContentHeightBinding: Binding<Int> { $bodyContentHeight }
    private var bodyCursorBinding: Binding<Int> { $state.map(\.editorBodyCursor) }
    private var bodyCursorLineBinding: Binding<Int> { $bodyCursorLine }
    private var followCursorBinding: Binding<Bool> { $followCursor }

    private var bodyMaxOffset: Int {
        max(0, bodyContentHeight - NotebookModel.bodyViewport)
    }

    private mutating func moveCursor(by delta: Int) {
        let current = state.editorBodyCursor
        let newValue = max(0, min(current + delta, state.editorBody.count))
        state.editorBodyCursor = newValue
    }
}
