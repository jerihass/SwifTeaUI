import SwifTeaCore
import SwifTeaUI

struct NotebookView: TUIView {
    private enum LayoutMode {
        case dualColumn
        case stacked
    }

    private let minimumColumns = 90
    private let minimumRows = 32
    private let stackedBreakpoint = 120

    let state: NotebookState
    let focus: NotebookFocusField?
    let titleBinding: Binding<String>
    let bodyBinding: Binding<String>
    let titleFocusBinding: Binding<Bool>
    let bodyFocusBinding: Binding<Bool>
    let bodyScrollBinding: Binding<Int>
    let bodyContentHeightBinding: Binding<Int>
    let bodyCursorBinding: Binding<Int>
    let bodyCursorLineBinding: Binding<Int>
    let followCursorBinding: Binding<Bool>

    private let bodyViewport = NotebookModel.bodyViewport

    var body: some TUIView {
        MinimumTerminalSize(columns: minimumColumns, rows: minimumRows) {
            renderMainLayout()
        } fallback: { size in
            renderResizeMessage(for: size)
        }
    }

    private func renderMainLayout() -> some TUIView {
        let size = TerminalDimensions.current
        let mode = layoutMode(for: size)
        let editorWidth = preferredEditorWidth(for: size, mode: mode)

        let textInputFocusStyle = FocusStyle(indicator: "", color: nil, bold: false)

        let editorContent = VStack(spacing: 1, alignment: .leading) {
            editorTitleView
            Text("Title:").foregroundColor(focus == .editorTitle ? .cyan : .yellow)
            TextField("Title...", text: titleBinding)
                .focusRingStyle(textInputFocusStyle)
                .focused(titleFocusBinding)
                .blinkingCursor()
            Text("Body:").foregroundColor(focus == .editorBody ? .cyan : .yellow)
            ScrollView(
                viewport: bodyViewport,
                offset: bodyScrollBinding,
                contentLength: bodyContentHeightBinding
            ) {
                TextEditor("Body...", text: bodyBinding, width: editorWidth)
                    .focusRingStyle(textInputFocusStyle)
                    .focused(bodyFocusBinding)
                    .blinkingCursor()
                    .cursorPosition(bodyCursorBinding)
                    .cursorLine(bodyCursorLineBinding)
            }
            .followingActiveLine(bodyCursorLineBinding, enabled: followCursorBinding)
            Text("")
            Text("Saved note: \(state.notes[state.selectedIndex].title)").foregroundColor(.green)
            Text("Status: \(state.statusMessage)").foregroundColor(.cyan)
        }
        let sidebar = Sidebar(
            title: "Notes",
            items: state.notes,
            selection: state.selectedIndex,
            isFocused: focus == .sidebar,
            style: sidebarStyle
        ) { note in
            note.title
        }

        let sidebarColumn = sidebar.padding(1)
        let editorColumn = editorContent.padding(1)

        let combined: AnyTUIView = {
            switch mode {
            case .dualColumn:
                return AnyTUIView(
                    Border(padding: 1, HStack(spacing: 2, horizontalAlignment: .leading, verticalAlignment: .top) {
                        sidebarColumn
                        editorColumn
                    })
                )
            case .stacked:
                return AnyTUIView(
                    Border(padding: 1, VStack(spacing: 1, alignment: .leading) {
                        sidebarColumn
                        editorColumn
                    })
                )
            }
        }()

        return VStack(spacing: 1, alignment: .leading) {
            Text("SwifTea Notebook").foregroundColor(.yellow).bold()
            Text("")
            combined
            Text("")
            statusBar
        }
    }

    private func renderResizeMessage(for size: TerminalSize) -> some TUIView {
        let header = Text("SwifTea Notebook").foregroundColor(.yellow).bold()
        let message = Border(
            VStack(spacing: 1, alignment: .leading) {
                Text("Terminal too small").foregroundColor(.yellow)
                Text("Minimum required: \(minimumColumns)×\(minimumRows)").foregroundColor(.cyan)
                Text("Current: \(size.columns)×\(size.rows)").foregroundColor(.cyan)
                Text("Resize the window to continue.").foregroundColor(.green)
            }
        )

        return VStack(spacing: 1, alignment: .leading) {
            header
            Text("")
            message
        }
    }

    private var focusDescription: String {
        switch focus {
        case .sidebar:
            return "sidebar"
        case .editorTitle:
            return "editor.title"
        case .editorBody:
            return "editor.body"
        case .none:
            return "none"
        }
    }

    private var statusBar: some TUIView {
        StatusBar(
            segmentSpacing: "  ",
            leading: [
                .init("Focus: \(focusDescription)", color: .yellow)
            ],
            trailing: statusSegments
        )
    }

    private func layoutMode(for size: TerminalSize) -> LayoutMode {
        size.columns >= stackedBreakpoint ? .dualColumn : .stacked
    }

    private func preferredEditorWidth(for size: TerminalSize, mode: LayoutMode) -> Int {
        switch mode {
        case .dualColumn:
            return 60
        case .stacked:
            let maxWidth = max(min(size.columns - 8, 70), 40)
            return maxWidth
        }
    }

    private var sidebarStyle: Sidebar<NotebookState.Note>.Style {
        var style = Sidebar<NotebookState.Note>.Style()
        if focus == .sidebar {
            style.titleColor = .cyan
        }
        style.showsBorder = false
        return style
    }

    private var editorTitleView: some TUIView {
        if focus == .editorTitle || focus == .editorBody {
            return Text(FocusStyle.default.apply(to: "Editor"))
        } else {
            return Text("Editor").foregroundColor(.yellow)
        }
    }

    private var statusSegments: [StatusBar.Segment] {
        switch focus {
        case .sidebar:
            return [
                .init("Enter edit", color: .cyan),
                .init("↑/↓ choose", color: .cyan),
                .init("Tab editor", color: .cyan)
            ]
        case .editorTitle:
            return [
                .init("Enter save", color: .cyan),
                .init("Tab body", color: .cyan),
                .init("Esc sidebar", color: .cyan)
            ]
        case .editorBody:
            return [
                .init("Enter save", color: .cyan),
                .init("↑/↓ scroll", color: .cyan),
                .init("←/→ move", color: .cyan),
                .init("Shift+Tab title", color: .cyan),
                .init("Esc sidebar", color: .cyan)
            ]
        case .none:
            return [
                .init("Tab next", color: .cyan),
                .init("Shift+Tab prev", color: .cyan)
            ]
        }
    }
}
