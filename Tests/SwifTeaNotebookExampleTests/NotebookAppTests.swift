import Testing
@testable import NotebookExample
@testable import SwifTeaCore

struct NotebookAppTests {

    @Test("Typing q in editor inserts character instead of quitting")
    func testTypingQInEditorDoesNotQuit() {
        var app = NotebookScene()
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
        let app = NotebookScene()
        let action = app.mapKeyToAction(.char("q"))
        #expect(action != nil)
        if let action {
            #expect(app.shouldExit(for: action))
        }
    }

    @Test("Pressing Enter in body preserves frame width")
    func testEnterInBodyKeepsFrameWidthStable() {
        var app = NotebookScene()
        let baseline = renderNotebook(app)
        let paddedBaseline = baseline.padded(toVisibleWidth: defaultSnapshotSize.columns)
        let baselineWidth = paddedBaseline.strippingANSI().components(separatedBy: "\n").map { $0.count }.max() ?? 0

        app.update(action: .setFocus(.editorBody))

        if let action = app.mapKeyToAction(.enter) {
            #expect(!app.shouldExit(for: action))
            app.update(action: action)
        } else {
            Issue.record("Expected enter key to map to an action when body is focused")
        }

        let after = renderNotebook(app)
        let paddedAfter = after.padded(toVisibleWidth: defaultSnapshotSize.columns)
        let afterWidth = paddedAfter.strippingANSI().components(separatedBy: "\n").map { $0.count }.max() ?? 0

        #expect(afterWidth == baselineWidth)
    }

    @Test("Arrow keys move the body cursor within the editor")
    func testBodyCursorMovement() {
        var app = NotebookScene()
        app.update(action: .setFocus(.editorBody))

        if let moveLeft = app.mapKeyToAction(.leftArrow) {
            app.update(action: moveLeft)
        } else {
            Issue.record("Expected left arrow to move the body cursor")
        }

        let rendered = renderNotebook(app).strippingANSI()
        #expect(rendered.contains("busy|."))
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
