@testable import SwifTeaNotebookExample

func renderNotebook(_ app: NotebookApp) -> String {
    app.view(model: app).render()
}
