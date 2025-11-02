import SwifTeaCore
import SwifTeaUI

struct NotebookView: TUIView {
    typealias Body = Never

    private static let minimumSize = TerminalSize(columns: 125, rows: 24)

    let state: NotebookState
    let focus: NotebookFocusField?
    let titleBinding: Binding<String>
    let bodyBinding: Binding<String>
    let titleFocusBinding: Binding<Bool>
    let bodyFocusBinding: Binding<Bool>

    var body: Never {
        fatalError("NotebookView has no body")
    }

    private func renderMainLayout() -> String {
        let editorContent = VStack(spacing: 1, alignment: .leading) {
            Text("Editor").foreground(.yellow)
            Text("Title:").foreground(focus == .editorTitle ? .cyan : .yellow)
            TextField("Title...", text: titleBinding, focus: titleFocusBinding)
            Text("Body:").foreground(focus == .editorBody ? .cyan : .yellow)
            TextArea("Body...", text: bodyBinding, focus: bodyFocusBinding, width: 60)
            Text("")
            Text("Saved note: \(state.notes[state.selectedIndex].title)").foreground(.green)
            Text("Status: \(state.statusMessage)").foreground(.cyan)
        }
        let editor = Border(editorContent)

        let sidebar = Sidebar(
            title: "Notes",
            items: state.notes,
            selection: state.selectedIndex,
            isFocused: focus == .sidebar
        ) { note in
            note.title
        }

        let layout = VStack(spacing: 1, alignment: .leading) {
            Text("SwifTea Notebook").foreground(.yellow).bolded()
            Text("")
            HStack(spacing: 6, horizontalAlignment: .leading, verticalAlignment: .top) {
                sidebar
                editor
            }
            Text("")
            StatusBar(
                segmentSpacing: "  ",
                leading: [
                    .init("Focus: \(focusDescription)", color: .yellow)
                ],
                trailing: [
                    .init("Tab next", color: .cyan),
                    .init("Shift+Tab prev", color: .cyan),
                    .init("↑/↓ choose note", color: .cyan),
                    .init("Enter save", color: .cyan)
                ]
            )
        }

        return layout.render()
    }

    private func renderResizeMessage(for size: TerminalSize) -> String {
        let header = Text("SwifTea Notebook").foreground(.yellow).bolded()
        let message = Border(
            VStack(spacing: 1, alignment: .leading) {
                Text("Terminal too small").foreground(.yellow)
                Text("Minimum required: \(Self.minimumSize.columns)×\(Self.minimumSize.rows)").foreground(.cyan)
                Text("Current: \(size.columns)×\(size.rows)").foreground(.cyan)
                Text("Resize the window to continue.").foreground(.green)
            }
        )

        let layout = VStack(spacing: 1, alignment: .leading) {
            header
            Text("")
            message
        }

        return layout.render()
    }

    func render() -> String {
        let size = TerminalDimensions.current
        guard size.columns >= Self.minimumSize.columns,
              size.rows >= Self.minimumSize.rows else {
            return renderResizeMessage(for: size)
        }

        return renderMainLayout()
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
}
