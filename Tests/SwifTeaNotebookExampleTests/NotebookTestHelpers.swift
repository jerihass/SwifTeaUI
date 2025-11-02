import SwifTeaCore
@testable import SwifTeaNotebookExample

let defaultSnapshotSize = TerminalSize(columns: 140, rows: 40)

func renderNotebook(
    _ app: NotebookApp,
    size: TerminalSize = defaultSnapshotSize
) -> String {
    return TerminalDimensions.withTemporarySize(size) {
        app.view(model: app).render()
    }
}
