import SwifTeaCore
import SwifTeaUI

struct CounterView: DeclarativeTUIView {
    let state: CounterState
    let focus: CounterFocusField?
    let titleBinding: Binding<String>
    let bodyBinding: Binding<String>
    let titleFocusBinding: Binding<Bool>
    let bodyFocusBinding: Binding<Bool>

    var body: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("SwifTea Counter").foreground(.yellow).bolded()
            Text("Count: \(state.count)").foreground(.green)
            Text("[u] up | [d] down | [←/→] also work | [q]/[Esc]/[Ctrl-C] quit").foreground(.cyan)
            Text("[Tab] move focus forward | [Shift+Tab] move back").foreground(.yellow)
            Spacer()
            Text("Note title:").foreground(focus == .noteTitle ? .cyan : .yellow)
            TextField("Title...", text: titleBinding, focus: titleFocusBinding)
            Text("Note body:").foreground(focus == .noteBody ? .cyan : .yellow)
            TextField("Body...", text: bodyBinding, focus: bodyFocusBinding)
            Text("Draft title: \(state.noteTitle)").foreground(.green)
            Text("Draft body: \(state.noteBody)").foreground(.green)
            Text("Last submitted -> title: \(state.lastSubmittedTitle), body: \(state.lastSubmittedBody)").foreground(.cyan)
            Text("Focus: \(focusDescription)").foreground(.yellow)
        }
    }

    private var focusDescription: String {
        switch focus {
        case .controls:
            return "controls"
        case .noteTitle:
            return "note.title"
        case .noteBody:
            return "note.body"
        case .none:
            return "none"
        }
    }
}
