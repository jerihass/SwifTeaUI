import Testing
@testable import SwifTeaNotebookExample

struct NotebookAppTests {

    @Test("Typing q in editor inserts character instead of quitting")
    func testTypingQInEditorDoesNotQuit() {
        var app = NotebookApp()
        app.update(action: .setFocus(.editorTitle))
        let before = renderNotebook(app).strippingANSI()

        let action = app.mapKeyToAction(.char("q"))
        #expect(action != nil)
        if let action {
            #expect(!app.shouldExit(for: action))
            app.update(action: action)
        }

        let after = renderNotebook(app).strippingANSI()
        #expect(after.contains("q"))
        #expect(after != before)
    }

    @Test("Typing q while sidebar focused still quits")
    func testTypingQInSidebarQuits() {
        let app = NotebookApp()
        let action = app.mapKeyToAction(.char("q"))
        #expect(action != nil)
        if let action {
            #expect(app.shouldExit(for: action))
        }
    }
}

private extension String {
    func strippingANSI() -> String {
        var result = ""
        var iterator = makeIterator()
        var inEscape = false

        while let character = iterator.next() {
            if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
                continue
            }

            if character == "\u{001B}" {
                inEscape = true
                continue
            }

            result.append(character)
        }

        return result
    }
}
