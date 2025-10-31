import SwifTeaCore
import SwifTeaUI

struct NotebookView: TUIView {
    let state: NotebookState
    let focus: NotebookFocusField?
    let titleBinding: Binding<String>
    let bodyBinding: Binding<String>
    let titleFocusBinding: Binding<Bool>
    let bodyFocusBinding: Binding<Bool>

    func render() -> String {
        let sidebarLines = state.notes.enumerated().map { index, note -> String in
            let pointer = (index == state.selectedIndex) ? ">" : " "
            let focusMarker = (focus == .sidebar && index == state.selectedIndex) ? "▌" : " "
            let lineContent = "\(pointer)\(focusMarker) \(note.title)"

            let color: ANSIColor
            if index == state.selectedIndex {
                color = (focus == .sidebar) ? .cyan : .yellow
            } else {
                color = .green
            }

            return color.rawValue + lineContent + ANSIColor.reset.rawValue
        }
        let sidebarBlock = sidebarLines.joined(separator: "\n")

        let sidebar = VStack(alignment: .center) {
            Text("Notes").foreground(.yellow)
            Text(sidebarBlock).foreground(.green)
        }

        let editor = VStack(spacing: 1, alignment: .leading) {
            Text("Editor").foreground(.yellow)
            Text("Title:").foreground(focus == .editorTitle ? .cyan : .yellow)
            TextField("Title...", text: titleBinding, focus: titleFocusBinding)
            Text("Body:").foreground(focus == .editorBody ? .cyan : .yellow)
            TextField("Body...", text: bodyBinding, focus: bodyFocusBinding)
            Text("")
            Text("Saved note: \(state.notes[state.selectedIndex].title)").foreground(.green)
            Text("Status: \(state.statusMessage)").foreground(.cyan)
        }

        let header = VStack(spacing: 1, alignment: .center, verticalAlignment: .center, height: 6) {
            Text("SwifTea Notebook").foreground(.yellow).bolded()
            Text("[Tab] next focus | [Shift+Tab] previous | [↑/↓] choose note | [Enter] save body").foreground(.cyan)
        }

        return VStack(spacing: 1, alignment: .center, verticalAlignment: .top) {
            header
            Text("")
            HStack(spacing: 6, horizontalAlignment: .leading, verticalAlignment: .center) {
                sidebar
                editor
            }
            Text("")
            Text("Focus: \(focusDescription)").foreground(.yellow)
        }.render()
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
