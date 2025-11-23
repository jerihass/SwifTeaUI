import Foundation
import SwifTeaUI

struct GalleryModel {
    enum Section: Int, CaseIterable {
        case counter
        case form
        case listSearch
        case listSelection
        case table
        case overlays

        var title: String {
            switch self {
            case .counter: return "Counter"
            case .form: return "Form & Focus"
            case .listSearch: return "List & Search"
            case .listSelection: return "List Selection"
            case .table: return "Table Snapshot"
            case .overlays: return "Overlays"
            }
        }

        var subtitle: String {
            switch self {
            case .counter:
                return "Minimal reducer-driven state."
            case .form:
                return "Text input, focus, and validation."
            case .listSearch:
                return "Incremental filtering with selection."
            case .listSelection:
                return "Checkbox and radio lists with focus."
            case .table:
                return "Columns, selection, and focus styling."
            case .overlays:
                return "Toast + modal presets via OverlayHost."
            }
        }

        var shortcut: Character {
            switch self {
            case .counter: return "1"
            case .form: return "2"
            case .listSearch: return "3"
            case .listSelection: return "4"
            case .table: return "5"
            case .overlays: return "6"
            }
        }

        func next(_ delta: Int) -> Section {
            let all = Section.allCases
            guard let currentIndex = all.firstIndex(of: self) else { return self }
            let count = all.count
            let offset = ((currentIndex + delta) % count + count) % count
            return all[offset]
        }
    }

    enum Action {
        case selectSection(Section)
        case cycleSection(Int)
        case counter(CounterDemoModel.Action)
        case form(FormDemoModel.Action)
        case list(ListSearchDemoModel.Action)
        case listSelection(ListSelectionDemoModel.Action)
        case table(TableDemoModel.Action)
        case overlayDemo(OverlayDemoModel.Action)
        case nextTheme
        case toggleHelp
        case quit
    }

    @State private var activeSection: Section
    private var counter: CounterDemoModel
    private var form: FormDemoModel
    private var list: ListSearchDemoModel
    private var listSelection: ListSelectionDemoModel
    private var table: TableDemoModel
    private var overlaysDemo: OverlayDemoModel
    @State private var overlays: OverlayPresenter
    private let themes: [SwifTeaTheme]
    @State private var themeIndex: Int

    init(
        activeSection: Section = .counter,
        counter: CounterDemoModel = CounterDemoModel(),
        form: FormDemoModel = FormDemoModel(),
        list: ListSearchDemoModel = ListSearchDemoModel(),
        listSelection: ListSelectionDemoModel = ListSelectionDemoModel(),
        table: TableDemoModel = TableDemoModel(),
        overlaysDemo: OverlayDemoModel = OverlayDemoModel(),
        overlays: OverlayPresenter = OverlayPresenter(),
        themes: [SwifTeaTheme] = [
            .lumenGlass,
            .basic
        ],
        themeIndex: Int = 0
    ) {
        self._activeSection = State(wrappedValue: activeSection)
        self.counter = counter
        self.form = form
        self.list = list
        self.listSelection = listSelection
        self.table = table
        self.overlaysDemo = overlaysDemo
        self._overlays = State(wrappedValue: overlays)
        self.themes = themes
        self._themeIndex = State(wrappedValue: max(0, min(themeIndex, themes.indices.last ?? 0)))
    }

    mutating func update(action: Action) {
        switch action {
        case .selectSection(let section):
            activeSection = section
            showSectionToast()
        case .cycleSection(let offset):
            activeSection = activeSection.next(offset)
            showSectionToast()
        case .counter(let action):
            counter.update(action: action)
        case .form(let action):
            form.update(action: action)
        case .list(let action):
            list.update(action: action)
        case .listSelection(let action):
            listSelection.update(action: action)
        case .table(let action):
            table.update(action: action)
        case .overlayDemo(let action):
            var demo = overlaysDemo
            var presenter = overlays
            demo.update(action: action, overlays: &presenter, theme: theme)
            overlaysDemo = demo
            overlays = presenter
        case .nextTheme:
            themeIndex = (themeIndex + 1) % themes.count
        case .toggleHelp:
            if overlays.hasModal {
                overlays.dismissModal()
            } else {
                presentHelpModal()
            }
        case .quit:
            break
        }
    }

    func makeView() -> some TUIView {
        let selectedView = viewForActiveSection()
        let galleryView = GalleryView(
            activeSection: activeSection,
            contentView: selectedView,
            shortcutsEnabled: sectionShortcutsEnabled,
            theme: theme
        )
        return OverlayHost(presenter: overlays, content: galleryView)
    }

    mutating func initializeEffects() {}

    mutating func handleTerminalResize(to newSize: TerminalSize) {
        _ = newSize
    }

    mutating func tickOverlays(_ delta: TimeInterval) {
        overlays.tick(deltaTime: delta)
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action { return true }
        return false
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        let allowGlobalShortcuts = sectionShortcutsEnabled
        if allowGlobalShortcuts {
            if case .char("?") = key {
                return .toggleHelp
            }
            if case .char("t") = key {
                return .nextTheme
            }
            if case .char("T") = key {
                return .nextTheme
            }
        }
        if case .ctrlC = key {
            return .quit
        }

        if case .char(let char) = key,
           let section = section(for: char),
           sectionShortcutsEnabled {
            return .selectSection(section)
        }

        if let sectionAction = actionForActiveSection(key) {
            return sectionAction
        }

        switch key {
        case .tab:
            return .cycleSection(1)
        case .backTab:
            return .cycleSection(-1)
        default:
            return nil
        }
    }

    private func section(for shortcut: Character) -> Section? {
        Section.allCases.first { $0.shortcut == shortcut }
    }

    private func actionForActiveSection(_ key: KeyEvent) -> Action? {
        switch activeSection {
        case .counter:
            guard let action = counter.mapKeyToAction(key) else { return nil }
            return .counter(action)
        case .form:
            guard let action = form.mapKeyToAction(key) else { return nil }
            return .form(action)
        case .listSearch:
            guard let action = list.mapKeyToAction(key) else { return nil }
            return .list(action)
        case .listSelection:
            guard let action = listSelection.mapKeyToAction(key) else { return nil }
            return .listSelection(action)
        case .table:
            guard let action = table.mapKeyToAction(key) else { return nil }
            return .table(action)
        case .overlays:
            guard let action = overlaysDemo.mapKeyToAction(key) else { return nil }
            return .overlayDemo(action)
        }
    }

    private func viewForActiveSection() -> AnyTUIView {
        switch activeSection {
        case .counter:
            return AnyTUIView(counter.makeView(theme: theme))
        case .form:
            return AnyTUIView(form.makeView(theme: theme))
        case .listSearch:
            return AnyTUIView(list.makeView(theme: theme))
        case .listSelection:
            return AnyTUIView(listSelection.makeView(theme: theme))
        case .table:
            return AnyTUIView(table.makeView(theme: theme))
        case .overlays:
            return AnyTUIView(overlaysDemo.makeView(theme: theme))
        }
    }

    private var theme: SwifTeaTheme {
        guard !themes.isEmpty else { return .lumenGlass }
        let index = themeIndex % themes.count
        return themes[index]
    }

    private var sectionShortcutsEnabled: Bool {
        switch activeSection {
        case .counter:
            return counter.allowsSectionShortcuts
        case .form:
            return form.allowsSectionShortcuts
        case .listSearch:
            return list.allowsSectionShortcuts
        case .listSelection:
            return listSelection.allowsSectionShortcuts
        case .table:
            return table.allowsSectionShortcuts
        case .overlays:
            return overlaysDemo.allowsSectionShortcuts
        }
    }

    private mutating func showSectionToast() {
        let message = "Switched to \(activeSection.title)"
        let toastStyle = OverlayPresenter.ToastStyle(
            accentColor: theme.accent,
            backgroundColor: theme.background ?? .black,
            textColor: theme.primaryText,
            icon: "★"
        )
        overlays.presentToast(
            placement: .bottom,
            duration: 2,
            style: toastStyle
        ) {
            Text(message)
        }
    }

    private mutating func presentHelpModal() {
        let theme = self.theme
        let infoColor = theme.info
        let style = OverlayPresenter.ModalStyle(
            accentColor: theme.accent,
            borderColor: theme.frameBorder,
            titleColor: theme.primaryText
        )
        overlays.presentModal(
            priority: 1,
            title: "Gallery Shortcuts",
            style: style
        ) {
            VStack(spacing: 1, alignment: .leading) {
                Text("[1…5] jump to section")
                Text("[Tab]/[Shift+Tab] cycle sections")
                Text("[T] cycle theme")
                Text("[?] toggle this help")
                Text("[Ctrl-C] quit")
            }
            .foregroundColor(infoColor)
        }
    }
}
