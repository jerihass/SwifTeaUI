struct NotebookState {
    struct Note {
        var title: String
        var body: String
    }

    var notes: [Note]
    var selectedIndex: Int
    var editorTitle: String
    var editorBody: String
    var editorBodyCursor: Int
    var statusMessage: String

    init() {
        self.notes = [
            Note(
                title: "Welcome to SwifTeaUI",
                body: "Use Tab to focus fields on the right, Shift+Tab to return here. This long introduction should stay visible even when the bottom of the screen is busy."
            ),
            Note(
                title: "Keyboard Shortcuts Overview",
                body: "↑/↓ move between notes when the sidebar is focused. Enter while editing the body saves. Longer descriptions ensure we validate vertical layout spacing."
            ),
            Note(
                title: "Ideas and Enhancements",
                body: "Try wiring this data into a persistence layer or renderer diff. Consider adding multi-line text editing and window resizing awareness for richer demos."
            )
        ]
        self.selectedIndex = 0
        self.editorTitle = notes[0].title
        self.editorBody = notes[0].body
        self.editorBodyCursor = notes[0].body.count
        self.statusMessage = "Tab to edit the welcome note and confirm longer content renders cleanly."
    }
}
