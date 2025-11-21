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
        case focusNext
        case focusPrevious
        case submit
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
        case .focusNext:
            focus = ring.move(from: focus, direction: .forward)
        case .focusPrevious:
            focus = ring.move(from: focus, direction: .backward)
        case .submit:
            showValidation = true
        }
    }

    var allowsSectionShortcuts: Bool {
        focus == nil
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .tab:
            return .focusNext
        case .backTab:
            return .focusPrevious
        case .enter:
            return .submit
        default:
            return nil
        }
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
                        Text("[Tab]/[Shift+Tab] Move • [Enter] Validate")
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
}

struct ListSearchDemoModel {
    struct Item: Identifiable {
        let id: Int
        let title: String
        let detail: String
    }

    enum Action {
        case moveSelection(Int)
    }

    @State private var query: String = ""
    @State private var selectedID: Item.ID? = 1
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
        case .moveSelection(let delta):
            moveSelection(delta)
        }
    }

    var allowsSectionShortcuts: Bool { searchFocused != true }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .upArrow, .char("k"): return .moveSelection(-1)
        case .downArrow, .char("j"): return .moveSelection(1)
        default: return nil
        }
    }

    func makeView(theme: SwifTeaTheme) -> some TUIView {
        let filtered = filteredItems()
        let selected = selectedID
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

                TextField("Type to filter (e.g., table)", text: $query)
                    .focusRingStyle(FocusStyle(indicator: "", color: nil, bold: false))
                    .focused($searchFocused.isFocused(true))
                    .blinkingCursor()

                if filtered.isEmpty {
                    Text("No matches.")
                        .foregroundColor(theme.warning)
                } else {
                    List(filtered, id: \.id, rowSpacing: 0, separator: .dashed()) { item in
                        row(for: item, selected: selected, theme: theme)
                    }
                }

                Border(
                    padding: 0,
                    color: theme.info,
                    background: theme.headerPanel.background ?? theme.background,
                    Text("[j]/[k] Move • Typing filters")
                        .foregroundColor(theme.info)
                        .padding(0)
                )
            }
        )
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
        selectedID = filtered[offset].id
    }

    private func row(for item: Item, selected: Item.ID?, theme: SwifTeaTheme) -> AnyTUIView {
        let isSelected = item.id == selected
        let title = highlight(text: item.title, theme: theme)
            .foregroundColor(isSelected ? theme.accent : theme.primaryText)
        let detail = Text(item.detail)
            .foregroundColor(theme.mutedText)

        let row = VStack(spacing: 0, alignment: .leading) {
            title
            detail
        }

        if isSelected {
            return AnyTUIView(
                Border(
                    padding: 0,
                    color: theme.accent,
                    background: theme.headerPanel.background ?? theme.background,
                    row.padding(0)
                )
            )
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
        TableSelectionConfiguration.single(
            $selectedID,
            focused: $focusedID,
            selectionStyle: .selected(backgroundColor: theme.success),
            focusedStyle: .focused(accent: theme.accent)
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
