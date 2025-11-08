import Testing
@testable import SwifTeaNotebookExample

struct NotebookRenderDiffTests {

    @Test("Notebook adjacent renders only differ when state changes")
    func testFrameDiffs() {
        var app = NotebookScene()
        let frame1 = renderNotebook(app)
        let frame2 = renderNotebook(app)
        #expect(frame1 == frame2)

        app.update(action: .selectNext)
        let frame3 = renderNotebook(app)
        #expect(frame2 != frame3)

        let frame4 = renderNotebook(app)
        #expect(frame3 == frame4)
    }
}
