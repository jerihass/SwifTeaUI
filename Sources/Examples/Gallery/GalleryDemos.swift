import Foundation
import SwifTeaUI

struct CounterDemoModel {
    enum Action {
        case increment
        case decrement
        case reset
    }

    @State private var count: Int = 3

    mutating func update(action: Action) {
        switch action {
        case .increment:
            count += 1
        case .decrement:
            count = max(0, count - 1)
        case .reset:
            count = 0
        }
    }

    var allowsSectionShortcuts: Bool { true }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("+"), .char("="): return .increment
        case .char("-"), .char("_"): return .decrement
        case .char("r"), .char("R"): return .reset
        default: return nil
        }
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: theme.background,
            VStack(spacing: 1, alignment: .leading) {
                Text("Counter & State")
                    .foregroundColor(theme.accent)
                    .bold()
                Text("Tiny reducer-driven counter with increment/decrement/reset.")
                    .foregroundColor(theme.info)
                HStack(spacing: 1, horizontalAlignment: .leading, verticalAlignment: .center) {
                    Text("Count:")
                        .foregroundColor(theme.primaryText)
                    Text("\(count)")
                        .foregroundColor(theme.success)
                        .bold()
                }
                HStack(spacing: 2, horizontalAlignment: .leading, verticalAlignment: .center) {
                    badge("[+]", label: "Increment", color: theme.accent)
                    badge("[-]", label: "Decrement", color: theme.warning)
                    badge("[R]", label: "Reset", color: theme.info)
                }
            }
        )
    }

    private func badge(_ shortcut: String, label: String, color: ANSIColor) -> some TUIView {
        Border(
            padding: 0,
            color: color,
            background: themeSafeBackground(color: color),
            Text("\(shortcut) \(label)")
                .foregroundColor(color)
                .bold()
                .padding(0)
        )
    }

    private func themeSafeBackground(color: ANSIColor) -> ANSIColor? {
        color == .black ? .brightBlack : .black
    }
}

struct FormDemoModel {
    enum Field: Hashable {
        case name
        case email
        case note
    }

    enum Action {
        enum Focus {
            case clear
            case next
            case previous
        }

        case focus(Focus)
        case submit
        case input(Field, TextFieldEvent)
    }

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var note: String = ""
    @FocusState private var focus: Field?
    @State private var showValidation: Bool = false
    private let ring = FocusRing<Field>([.name, .email, .note])

    init(
        name: String = "",
        email: String = "",
        note: String = "",
        initialFocus: Field? = .name
    ) {
        self._name = State(wrappedValue: name)
        self._email = State(wrappedValue: email)
        self._note = State(wrappedValue: note)
        self._focus = FocusState(wrappedValue: initialFocus)
    }

    mutating func update(action: Action) {
        switch action {
        case .focus(.clear):
            focus = nil
        case .focus(.next):
            focus = ring.move(from: focus, direction: .forward)
        case .focus(.previous):
            focus = ring.move(from: focus, direction: .backward)
        case .submit:
            showValidation = true
        case .input(let field, let event):
            apply(event, to: field)
        }
    }

    var allowsSectionShortcuts: Bool {
        focus == nil
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .tab:
            return .focus(.next)
        case .backTab:
            return .focus(.previous)
        case .enter:
            return .submit
        case .escape:
            return .focus(.clear)
        default:
            break
        }

        guard let focusedField = focus, let event = textFieldEvent(from: key) else {
            return nil
        }
        return .input(focusedField, event)
    }

    private var stopEditHint: String {
        focus != nil ? " • [ESC] to stop editing." : ""
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: theme.background,
            VStack(spacing: 1, alignment: .leading) {
                Text("Form & Focus")
                    .foregroundColor(theme.accent)
                    .bold()
                Text("TextField/TextEditor with simple validation and focus order.")
                    .foregroundColor(theme.info)

                Text("Name")
                    .foregroundColor(focus == .name ? theme.accent : theme.primaryText)
                TextField("Jane Appleseed", text: $name)
                    .focusRingStyle(FocusStyle(indicator: "", color: nil, bold: false))
                    .focused($focus.isFocused(.name))
                    .blinkingCursor()

                Text("Email")
                    .foregroundColor(focus == .email ? theme.accent : theme.primaryText)
                TextField("hello@example.com", text: $email)
                    .focusRingStyle(FocusStyle(indicator: "", color: nil, bold: false))
                    .focused($focus.isFocused(.email))
                    .blinkingCursor()

                Text("Notes")
                    .foregroundColor(focus == .note ? theme.accent : theme.primaryText)
                TextEditor("Optional notes...", text: $note, width: 60)
                    .focusRingStyle(FocusStyle(indicator: "", color: nil, bold: false))
                    .focused($focus.isFocused(.note))
                    .blinkingCursor()
                    .cursorLine(.constant(0))

                HStack(spacing: 2, horizontalAlignment: .leading, verticalAlignment: .center) {
                    Border(
                        padding: 0,
                        color: theme.info,
                        background: theme.headerPanel.background ?? theme.background,
                        Text("[Tab]/[Shift+Tab] Move • [Enter] Validate" + stopEditHint)
                            .foregroundColor(theme.info)
                            .padding(0)
                    )
                }

                if showValidation {
                    validationMessages
                }
            }
        )
    }

    private var validationMessages: some TUIView {
        let messages = makeValidationMessages()
        return VStack(spacing: 0, alignment: .leading) {
            ForEach(messages, id: \.self) { message in
                Text(message)
                    .foregroundColor(.brightYellow)
            }
        }
    }

    private func makeValidationMessages() -> [String] {
        var messages: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("• Name is required.")
        }
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("• Email is required.")
        } else if !email.contains("@") {
            messages.append("• Email should include '@'.")
        }
        return messages.isEmpty ? ["Looks good!"] : messages
    }

    private mutating func apply(_ event: TextFieldEvent, to field: Field) {
        switch field {
        case .name:
            $name.apply(event)
        case .email:
            $email.apply(event)
        case .note:
            $note.apply(event)
        }
    }
}

struct ListSearchDemoModel {
    struct Item: Identifiable {
        let id: Int
        let title: String
        let detail: String
    }

    enum Action {
        enum Focus {
            case clear
            case filter
        }

        case focus(Focus)
        case moveSelection(Int)
        case text(TextFieldEvent)
    }

    @State private var query: String = ""
    @State private var selectedID: Item.ID? = 1
    @State private var focusedID: Item.ID? = 1
    @FocusState private var searchFocused: Bool?
    private let items: [Item] = [
        .init(id: 1, title: "SwifTeaUI", detail: "ANSI-native view DSL"),
        .init(id: 2, title: "Counter", detail: "Minimal state demo"),
        .init(id: 3, title: "Task Runner", detail: "Async effects"),
        .init(id: 4, title: "Notebook", detail: "Basic text editor"),
        .init(id: 5, title: "Table", detail: "Column definitions"),
        .init(id: 6, title: "Overlay", detail: "Toast + modal host")
    ]

    init(
        query: String = "",
        selectedID: Item.ID? = 1,
        searchFocused: Bool? = true
    ) {
        self._query = State(wrappedValue: query)
        self._selectedID = State(wrappedValue: selectedID)
        self._searchFocused = FocusState(wrappedValue: searchFocused)
    }

    mutating func update(action: Action) {
        switch action {
        case .focus(.clear):
            searchFocused = false
        case .focus(.filter):
            searchFocused = true
        case let .moveSelection(delta):
            moveSelection(delta)
        case .text(let event):
            $query.apply(event)
            maintainSelection()
        }
    }

    var allowsSectionShortcuts: Bool { searchFocused != true }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        if searchFocused == true {
            switch key {
            case .upArrow: return .moveSelection(-1)
            case .downArrow: return .moveSelection(1)
            case .enter: return .focus(.clear)
            default: break
            }
            if let event = textFieldEvent(from: key) {
                return .text(event)
            }
            return nil
        }

        switch key {
        case .upArrow, .char("k"): return .moveSelection(-1)
        case .downArrow, .char("j"): return .moveSelection(1)
        case .enter: return .focus(.filter)
        default: break
        }

        return nil
    }

    /// Maintains selection after filter changes and selection is still valid.
    private mutating func maintainSelection() {
        let filtered = filteredItems()
        guard !filtered.isEmpty else { return }
        guard let currentIndex = filtered.firstIndex(where: { $0.id == selectedID }) ?? filtered.indices.first else {
            return
        }

        let next = filtered[currentIndex].id
        selectedID = next
        focusedID = next
    }

    private var placeholder: String {
        let focused = searchFocused ?? false
        return focused ? "Type to filter (e.g., table)" : "Press [ENTER] to filter"
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        let filtered = filteredItems()
        return Border(
            padding: 1,
            color: theme.frameBorder,
            background: theme.background,
            VStack(spacing: 1, alignment: .leading) {
                Text("List & Search")
                    .foregroundColor(theme.accent)
                    .bold()
                Text("Incremental filter with highlighted matches.")
                    .foregroundColor(theme.info)

                TextField(placeholder, text: $query)
                    .focusRingStyle(FocusStyle(indicator: "", color: nil, bold: false))
                    .focused($searchFocused.isFocused(true))
                    .blinkingCursor()

                if filtered.isEmpty {
                    Text("No matches.")
                        .foregroundColor(theme.warning)
                } else {
                    List(
                        filtered,
                        id: \.id,
                        rowSpacing: 0,
                        separator: .dashed(),
                        selection: selectionConfiguration(theme: theme)
                    ) { item in
                        row(for: item, theme: theme)
                    }
                }
                Border(
                    padding: 0,
                    color: theme.info,
                    background: theme.headerPanel.background ?? theme.background,
                    Text(hints)
                        .foregroundColor(theme.info)
                        .padding(0)
                )
            }
        )
    }

    private var hints: String {
        let focused = searchFocused ?? false
        let hint = switch (focused, query.isEmpty) {
        case (true, _):
            "Type to filter • [ENTER] stop filtering"
        case (false, _):
            "[j]/[k]/↑/↓ move • [ENTER] start filtering"
        }
        return hint
    }

    private func filteredItems() -> [Item] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.title.lowercased().contains(trimmed.lowercased()) ||
            $0.detail.lowercased().contains(trimmed.lowercased())
        }
    }

    private mutating func moveSelection(_ delta: Int) {
        let filtered = filteredItems()
        guard !filtered.isEmpty else { return }
        guard let currentIndex = filtered.firstIndex(where: { $0.id == selectedID }) ?? filtered.indices.first else {
            return
        }
        let count = filtered.count
        let offset = ((currentIndex + delta) % count + count) % count
        let next = filtered[offset].id
        selectedID = next
        focusedID = next
    }

    private func row(for item: Item, theme: SwifTeaTheme) -> AnyTUIView {
        let title = highlight(text: item.title, theme: theme)
            .foregroundColor(theme.primaryText)
        let detail = Text(item.detail)
            .foregroundColor(theme.mutedText)

        let row = VStack(spacing: 0, alignment: .leading) {
            title
            detail
        }
        return AnyTUIView(row)
    }

    private func highlight(text: String, theme: SwifTeaTheme) -> Text {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Text(text) }
        if text.lowercased().contains(trimmed.lowercased()) {
            return Text(text).bold().foregroundColor(theme.accent)
        }
        return Text(text)
    }

    private func selectionConfiguration(theme: SwifTeaTheme) -> ListSelectionConfiguration<Item.ID> {
        ListSelectionConfiguration.single(
            $selectedID,
            focused: $focusedID,
            selectionStyle: TableRowStyle.selected(
                foregroundColor: theme.selectionForeground,
                backgroundColor: theme.selectionBackground ?? theme.success
            ),
            focusedStyle: TableRowStyle.focused(accent: theme.accent)
        )
    }
}

struct ListSelectionDemoModel {
    struct Task: Identifiable {
        let id: Int
        let label: String
    }

    struct Choice: Identifiable {
        let id: Int
        let label: String
    }

    enum Action {
        case moveTasksFocus(Int)
        case toggleTask
        case moveChoiceFocus(Int)
        case chooseChoice
    }

    @State private var tasks: [Task] = [
        .init(id: 1, label: "Compile"),
        .init(id: 2, label: "Run tests"),
        .init(id: 3, label: "Record snapshot")
    ]
    @State private var selectedTasks: Set<Task.ID> = [1]
    @State private var focusedTaskID: Task.ID? = 1
    @State private var choices: [Choice] = [
        .init(id: 1, label: "Deploy to staging"),
        .init(id: 2, label: "Deploy to production")
    ]
    @State private var selectedChoice: Choice.ID? = 1
    @State private var focusedChoiceID: Choice.ID? = 1

    init(
        tasks: [Task] = [
            .init(id: 1, label: "Compile"),
            .init(id: 2, label: "Run tests"),
            .init(id: 3, label: "Record snapshot")
        ],
        selectedTasks: Set<Task.ID> = [1],
        focusedTaskID: Task.ID? = 1,
        choices: [Choice] = [
            .init(id: 1, label: "Deploy to staging"),
            .init(id: 2, label: "Deploy to production")
        ],
        selectedChoice: Choice.ID? = 1,
        focusedChoiceID: Choice.ID? = 1
    ) {
        self._tasks = State(wrappedValue: tasks)
        self._selectedTasks = State(wrappedValue: selectedTasks)
        self._focusedTaskID = State(wrappedValue: focusedTaskID)
        self._choices = State(wrappedValue: choices)
        self._selectedChoice = State(wrappedValue: selectedChoice)
        self._focusedChoiceID = State(wrappedValue: focusedChoiceID)
    }

    mutating func update(action: Action) {
        switch action {
        case .moveTasksFocus(let delta):
            moveTasksFocus(delta)
        case .toggleTask:
            toggleTask()
        case .moveChoiceFocus(let delta):
            moveChoiceFocus(delta)
        case .chooseChoice:
            chooseChoice()
        }
    }

    var allowsSectionShortcuts: Bool { true }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .upArrow, .char("w"): return .moveTasksFocus(-1)
        case .downArrow, .char("s"): return .moveTasksFocus(1)
        case .char(" "): return .toggleTask
        case .leftArrow, .char("a"): return .moveChoiceFocus(-1)
        case .rightArrow, .char("d"): return .moveChoiceFocus(1)
        case .enter: return .chooseChoice
        default: return nil
        }
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: theme.background,
            VStack(spacing: 1, alignment: .leading) {
                Text("List Selection")
                    .foregroundColor(theme.accent)
                    .bold()
                Text("Checkbox and radio lists with focus styling.")
                    .foregroundColor(theme.info)

                Text("Checkbox list (w/s to move, space to toggle)")
                    .foregroundColor(theme.accent)
                    .bold()
                List(
                    tasks,
                    id: \.id,
                    rowSpacing: 0,
                    separator: .none,
                    selection: .multiple(
                        $selectedTasks,
                        focused: $focusedTaskID,
                        selectionStyle: TableRowStyle.selected(
                            foregroundColor: theme.selectionForeground,
                            backgroundColor: theme.selectionBackground ?? theme.success
                        ),
                        focusedStyle: TableRowStyle.focused(accent: theme.accent)
                    )
                ) { task in
                    Checkbox(
                        task.label,
                        isChecked: selectedTasks.contains(task.id),
                        isFocused: focusedTaskID == task.id,
                        accent: theme.accent
                    )
                }

                Text("Radio list (a/d to move, enter to choose)")
                    .foregroundColor(theme.accent)
                    .bold()
                List(
                    choices,
                    id: \.id,
                    rowSpacing: 0,
                    separator: .none,
                    selection: .single(
                        $selectedChoice,
                        focused: $focusedChoiceID,
                        selectionStyle: TableRowStyle.selected(
                            foregroundColor: theme.selectionForeground,
                            backgroundColor: theme.selectionBackground ?? theme.success
                        ),
                        focusedStyle: TableRowStyle.focused(accent: theme.accent)
                    )
                ) { choice in
                    RadioButton(
                        choice.label,
                        isSelected: selectedChoice == choice.id,
                        isFocused: focusedChoiceID == choice.id,
                        accent: theme.accent
                    )
                }

                Border(
                    padding: 0,
                    color: theme.info,
                    background: theme.headerPanel.background ?? theme.background,
                    Text("[w]/[s]/↑/↓ move checkboxes • Space toggles • [a]/[d]/←/→ move radio • Enter picks")
                        .foregroundColor(theme.info)
                        .padding(0)
                )
            }
        )
    }

    private mutating func moveTasksFocus(_ delta: Int) {
        guard !tasks.isEmpty else { return }
        guard let currentIndex = tasks.firstIndex(where: { $0.id == focusedTaskID }) ?? tasks.indices.first else {
            return
        }
        let count = tasks.count
        let offset = ((currentIndex + delta) % count + count) % count
        let next = tasks[offset].id
        focusedTaskID = next
    }

    private mutating func toggleTask() {
        guard let focusedTaskID else { return }
        if selectedTasks.contains(focusedTaskID) {
            selectedTasks.remove(focusedTaskID)
        } else {
            selectedTasks.insert(focusedTaskID)
        }
    }

    private mutating func moveChoiceFocus(_ delta: Int) {
        guard !choices.isEmpty else { return }
        guard let currentIndex = choices.firstIndex(where: { $0.id == focusedChoiceID }) ?? choices.indices.first else {
            return
        }
        let count = choices.count
        let offset = ((currentIndex + delta) % count + count) % count
        let next = choices[offset].id
        focusedChoiceID = next
    }

    private mutating func chooseChoice() {
        guard let focusedChoiceID else { return }
        selectedChoice = focusedChoiceID
    }
}

struct TableDemoModel {
    struct Row: Identifiable {
        let id: Int
        let name: String
        let status: String
        let duration: String
    }

    enum Action {
        case move(Int)
    }

    @State private var rows: [Row] = [
        .init(id: 1, name: "Compile", status: "Running", duration: "8s"),
        .init(id: 2, name: "Tests", status: "Pending", duration: "—"),
        .init(id: 3, name: "Docs", status: "Idle", duration: "0s"),
        .init(id: 4, name: "Preview", status: "Running", duration: "2s")
    ]
    @State private var selectedID: Row.ID? = 1
    @State private var focusedID: Row.ID? = 1

    mutating func update(action: Action) {
        switch action {
        case .move(let delta):
            moveFocus(delta)
        }
    }

    var allowsSectionShortcuts: Bool { true }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .upArrow, .char("k"): return .move(-1)
        case .downArrow, .char("j"): return .move(1)
        default: return nil
        }
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: theme.background,
            VStack(spacing: 1, alignment: .leading) {
                Text("Table Snapshot")
                    .foregroundColor(theme.accent)
                    .bold()
                Text("ANSI-aware columns with selection and focus styling.")
                    .foregroundColor(theme.info)

                Table(
                    rows,
                    divider: .line(color: theme.frameBorder, isBold: false),
                    selection: selectionConfiguration(theme: theme),
                    rowStyle: { row, _ in
                        guard row.id == focusedID else { return nil }
                        return TableRowStyle.focused(accent: theme.accent)
                    }
                ) {
                    TableColumn("Task", value: \TableDemoModel.Row.name, width: .flex(min: 10))
                    TableColumn("Status", value: \TableDemoModel.Row.status, width: .fixed(10))
                    TableColumn("Duration", value: \TableDemoModel.Row.duration, width: .fixed(8), alignment: .trailing)
                }

                Border(
                    padding: 0,
                    color: theme.info,
                    background: theme.headerPanel.background ?? theme.background,
                    Text("[j]/[k] Move • Single selection")
                        .foregroundColor(theme.info)
                        .padding(0)
                )
            }
        )
    }

    private func selectionConfiguration(theme: SwifTeaTheme) -> TableSelectionConfiguration<Row.ID> {
        let selectionColors = self.selectionColors(for: theme)
        return TableSelectionConfiguration.single(
            $selectedID,
            focused: $focusedID,
            selectionStyle: .selected(
                foregroundColor: selectionColors.foreground,
                backgroundColor: selectionColors.background
            ),
            focusedStyle: .focused(accent: theme.accent)
        )
    }

    private func selectionColors(for theme: SwifTeaTheme) -> (foreground: ANSIColor?, background: ANSIColor) {
        (
            foreground: theme.selectionForeground,
            background: theme.selectionBackground ?? theme.success
        )
    }

    private mutating func moveFocus(_ delta: Int) {
        guard !rows.isEmpty else { return }
        guard let currentIndex = rows.firstIndex(where: { $0.id == focusedID }) ?? rows.indices.first else {
            return
        }
        let count = rows.count
        let offset = ((currentIndex + delta) % count + count) % count
        let nextID = rows[offset].id
        focusedID = nextID
        selectedID = nextID
    }
}

struct OverlayDemoModel {
    enum Action {
        case showToast
        case showModal
    }

    var allowsSectionShortcuts: Bool { true }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("t"), .char("T"): return .showToast
        case .char("m"), .char("M"): return .showModal
        default: return nil
        }
    }

    mutating func update(action: Action, overlays: inout OverlayPresenter, theme: SwifTeaTheme) {
        switch action {
        case .showToast:
            let style = OverlayPresenter.ToastStyle(
                accentColor: theme.accent,
                backgroundColor: theme.background ?? .black,
                textColor: theme.primaryText,
                icon: "•"
            )
            overlays.presentToast(placement: .bottom, duration: 2, style: style) {
                Text("Background sync finished.")
            }
        case .showModal:
            let style = OverlayPresenter.ModalStyle(
                accentColor: theme.accent,
                borderColor: theme.frameBorder,
                titleColor: theme.primaryText
            )
            overlays.presentModal(priority: 2, title: "Overlay Demo", style: style) {
                VStack(spacing: 1, alignment: .leading) {
                    Text("Modals stack above toasts and other content.")
                        .foregroundColor(theme.primaryText)
                    Text("Press '?' to close or 'Ctrl-C' to quit.")
                        .foregroundColor(theme.info)
                }
            }
        }
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: theme.background,
            VStack(spacing: 1, alignment: .leading) {
                Text("Overlays & Notifications")
                    .foregroundColor(theme.accent)
                    .bold()
                Text("Toast + modal presets using OverlayPresenter/OverlayHost.")
                    .foregroundColor(theme.info)
                Border(
                    padding: 0,
                    color: theme.info,
                    background: theme.headerPanel.background ?? theme.background,
                    Text("[T] Toast • [M] Modal")
                        .foregroundColor(theme.info)
                        .padding(0)
                )
            }
        )
    }
}
