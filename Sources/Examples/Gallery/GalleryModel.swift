import Foundation
import SwifTeaUI

struct GalleryModel {
    enum Section: Int, CaseIterable {
        case notebook
        case tasks
        case packages

        var title: String {
            switch self {
            case .notebook: return "Notebook"
            case .tasks: return "Task Runner"
            case .packages: return "Package List"
            }
        }

        var shortcut: Character {
            switch self {
            case .notebook: return "1"
            case .tasks: return "2"
            case .packages: return "3"
            }
        }

        func next(_ delta: Int) -> Section {
            let all = Section.allCases
            guard let currentIndex = all.firstIndex(of: self) else { return self }
            let count = all.count
            guard count > 0 else { return self }
            let offset = ((currentIndex + delta) % count + count) % count
            return all[offset]
        }
    }

    enum Action {
        case selectSection(Section)
        case cycleSection(Int)
        case notebook(NotebookModel.Action)
        case tasks(TaskRunnerModel.Action)
        case packages(PackageListModel.Action)
        case toggleHelp
        case quit
    }

    @State private var activeSection: Section
    private var notebook: NotebookModel
    private var taskRunner: TaskRunnerModel
    private var packageList: PackageListModel
    @State private var overlays: OverlayPresenter
    private let theme: SwifTeaTheme

    init(
        activeSection: Section = .notebook,
        notebook: NotebookModel = NotebookModel(),
        taskRunner: TaskRunnerModel? = nil,
        packageList: PackageListModel = PackageListModel(),
        overlays: OverlayPresenter = OverlayPresenter(),
        theme: SwifTeaTheme = .bubbleTeaNeon
    ) {
        self._activeSection = State(wrappedValue: activeSection)
        self.notebook = notebook
        self.taskRunner = taskRunner ?? TaskRunnerModel(effects: Self.makeTaskRunnerEffects())
        self.packageList = packageList
        self._overlays = State(wrappedValue: overlays)
        self.theme = theme
    }

    mutating func update(action: Action) {
        switch action {
        case .selectSection(let section):
            activeSection = section
            showSectionToast()
        case .cycleSection(let offset):
            activeSection = activeSection.next(offset)
            showSectionToast()
        case .notebook(let notebookAction):
            notebook.update(action: notebookAction)
        case .tasks(let taskAction):
            taskRunner.update(action: taskAction)
        case .packages(let packageAction):
            packageList.update(action: packageAction)
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

    mutating func initializeEffects() {
        taskRunner.initializeEffects()
    }

    mutating func handleTerminalResize(to newSize: TerminalSize) {
        taskRunner.updateTerminalMetrics(TerminalMetrics(size: newSize))
    }

    mutating func tickOverlays(_ delta: TimeInterval) {
        overlays.tick(deltaTime: delta)
    }

    func shouldExit(for action: Action) -> Bool {
        switch action {
        case .quit:
            return true
        case .notebook(let inner):
            return notebook.shouldExit(for: inner)
        case .tasks(let inner):
            return taskRunner.shouldExit(for: inner)
        case .packages(let inner):
            return packageList.shouldExit(for: inner)
        case .selectSection, .cycleSection, .toggleHelp:
            return false
        }
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        if case .char(let char) = key, let section = section(for: char) {
            if sectionShortcutsEnabled {
                return .selectSection(section)
            }
        }

        switch key {
        case .char("?"):
            return .toggleHelp
        case .ctrlC:
            return .quit
        case .tab:
            if activeSection == .notebook {
                return notebookAction(for: key)
            }
            return .cycleSection(1)
        case .backTab:
            if activeSection == .notebook {
                return notebookAction(for: key)
            }
            return .cycleSection(-1)
        default:
            break
        }

        return actionForActiveSection(key)
    }

    private func notebookAction(for key: KeyEvent) -> Action? {
        guard let action = notebook.mapKeyToAction(key) else { return nil }
        if notebook.shouldExit(for: action) {
            return .quit
        }
        return .notebook(action)
    }

    private func taskRunnerAction(for key: KeyEvent) -> Action? {
        guard let action = taskRunner.mapKeyToAction(key) else { return nil }
        if taskRunner.shouldExit(for: action) {
            return .quit
        }
        return .tasks(action)
    }

    private func packageListAction(for key: KeyEvent) -> Action? {
        guard let action = packageList.mapKeyToAction(key) else { return nil }
        if packageList.shouldExit(for: action) {
            return .quit
        }
        return .packages(action)
    }

    private func actionForActiveSection(_ key: KeyEvent) -> Action? {
        switch activeSection {
        case .notebook:
            return notebookAction(for: key)
        case .tasks:
            return taskRunnerAction(for: key)
        case .packages:
            return packageListAction(for: key)
        }
    }

    private func section(for shortcut: Character) -> Section? {
        Section.allCases.first { $0.shortcut == shortcut }
    }

    private func viewForActiveSection() -> AnyTUIView {
        switch activeSection {
        case .notebook:
            return AnyTUIView(notebook.makeView())
        case .tasks:
            return AnyTUIView(taskRunner.makeView())
        case .packages:
            return AnyTUIView(packageList.makeView())
        }
    }

    private var sectionShortcutsEnabled: Bool {
        switch activeSection {
        case .notebook:
            return notebook.allowsSectionShortcuts
        case .tasks, .packages:
            return true
        }
    }

    private static func makeTaskRunnerEffects() -> TaskRunnerModel.EffectRuntime {
        TaskRunnerModel.EffectRuntime(
            dispatch: { effect, id, cancelExisting in
                let wrapped = effect.map(GalleryModel.Action.tasks)
                SwifTea.dispatch(wrapped, id: id, cancelExisting: cancelExisting)
            },
            cancel: { id in
                SwifTea.cancelEffects(withID: id)
            }
        )
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
        let style = OverlayPresenter.ModalStyle(
            accentColor: theme.accent,
            borderColor: theme.frameBorder,
            titleColor: theme.primaryText
        )
        let infoColor = theme.info
        overlays.presentModal(
            priority: 1,
            title: "Gallery Shortcuts",
            style: style
        ) {
            VStack(spacing: 1, alignment: .leading) {
                Text("[1]/[2]/[3] select section")
                Text("[Tab]/[Shift+Tab] cycle sections")
                Text("[?] toggle this help")
                Text("[Ctrl-C] quit")
            }
            .foregroundColor(infoColor)
        }
    }
}
