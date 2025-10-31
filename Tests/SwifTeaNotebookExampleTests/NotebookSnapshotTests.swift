import Testing
@testable import SwifTeaNotebookExample
import SwifTeaCore

struct NotebookSnapshotTests {

    @Test("Initial layout renders expected snapshot")
    func testInitialLayoutSnapshot() {
        let snapshot = renderInitialNotebook()
        let sanitized = snapshot.strippingANSI()

        #expect(snapshot.contains(ANSIColor.cyan.rawValue + ">▌ Welcome to SwifTeaUI" + ANSIColor.reset.rawValue))

        let expectedLines = [
            "SwifTea Notebook",
            "",
            "[Tab] next focus | [Shift+Tab] previous | [↑/↓] choose note | [Enter] save body",
            "",
            "",
            "",
            "Notes                               Editor",
            ">▌ Welcome to SwifTeaUI",
            "   Keyboard Shortcuts Overview      Title:",
            "   Ideas and Enhancements",
            "                                    Welcome to SwifTeaUI",
            "",
            "                                    Body:",
            "",
            "                                    Use Tab to focus fields on the right, Shift+Tab to return",
            "                                    here. This long introduction should stay visible even when",
            "                                    the bottom of the screen is busy.",
            "",
            "",
            "",
            "                                    Saved note: Welcome to SwifTeaUI",
            "",
            "                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.",
            "",
            "",
            "",
            "Focus: sidebar"
        ]

        let expected = expectedLines.joined(separator: "\n")

        #expect(sanitized.removingTrailingSpacesPerLine() == expected)
    }

    @Test("Title field focus snapshot shows cursor in title")
    func testTitleFieldFocusSnapshot() {
        var app = NotebookApp()
        app.update(action: .setFocus(.editorTitle))

        let snapshot = renderNotebook(app)
        let sanitized = snapshot.strippingANSI()

        #expect(snapshot.contains(ANSIColor.cyan.rawValue + "Title:" + ANSIColor.reset.rawValue))

        let expectedLines = [
            "SwifTea Notebook",
            "",
            "[Tab] next focus | [Shift+Tab] previous | [↑/↓] choose note | [Enter] save body",
            "",
            "",
            "",
            "Notes                               Editor",
            ">  Welcome to SwifTeaUI",
            "   Keyboard Shortcuts Overview      Title:",
            "   Ideas and Enhancements",
            "                                    Welcome to SwifTeaUI|",
            "",
            "                                    Body:",
            "",
            "                                    Use Tab to focus fields on the right, Shift+Tab to return",
            "                                    here. This long introduction should stay visible even when",
            "                                    the bottom of the screen is busy.",
            "",
            "",
            "",
            "                                    Saved note: Welcome to SwifTeaUI",
            "",
            "                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.",
            "",
            "",
            "",
            "Focus: editor.title"
        ]

        let expected = expectedLines.joined(separator: "\n")

        #expect(sanitized.removingTrailingSpacesPerLine() == expected)
    }

    @Test("Body field focus snapshot shows cursor in body")
    func testBodyFieldFocusSnapshot() {
        var app = NotebookApp()
        app.update(action: .setFocus(.editorBody))

        let snapshot = renderNotebook(app)
        let sanitized = snapshot.strippingANSI()

        #expect(snapshot.contains(ANSIColor.cyan.rawValue + "Body:" + ANSIColor.reset.rawValue))

        let expectedLines = [
            "SwifTea Notebook",
            "",
            "[Tab] next focus | [Shift+Tab] previous | [↑/↓] choose note | [Enter] save body",
            "",
            "",
            "",
            "Notes                               Editor",
            ">  Welcome to SwifTeaUI",
            "   Keyboard Shortcuts Overview      Title:",
            "   Ideas and Enhancements",
            "                                    Welcome to SwifTeaUI",
            "",
            "                                    Body:",
            "",
            "                                    Use Tab to focus fields on the right, Shift+Tab to return",
            "                                    here. This long introduction should stay visible even when",
            "                                    the bottom of the screen is busy.|",
            "",
            "",
            "",
            "                                    Saved note: Welcome to SwifTeaUI",
            "",
            "                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.",
            "",
            "",
            "",
            "Focus: editor.body"
        ]

        let expected = expectedLines.joined(separator: "\n")

        #expect(sanitized.removingTrailingSpacesPerLine() == expected)
    }

    @Test("Sidebar selection snapshot highlights second note")
    func testSidebarSelectionSnapshot() {
        var app = NotebookApp()
        app.update(action: .selectNext)

        let snapshot = renderNotebook(app)
        let sanitized = snapshot.strippingANSI()

        #expect(snapshot.contains(ANSIColor.cyan.rawValue + ">▌ Keyboard Shortcuts Overview" + ANSIColor.reset.rawValue))

        let expectedLines = [
            "SwifTea Notebook",
            "",
            "[Tab] next focus | [Shift+Tab] previous | [↑/↓] choose note | [Enter] save body",
            "",
            "",
            "",
            "Notes                               Editor",
            "   Welcome to SwifTeaUI",
            ">▌ Keyboard Shortcuts Overview      Title:",
            "   Ideas and Enhancements",
            "                                    Keyboard Shortcuts Overview",
            "",
            "                                    Body:",
            "",
            "                                    ↑/↓ move between notes when the sidebar is focused. Enter",
            "                                    while editing the body saves. Longer descriptions ensure we",
            "                                    validate vertical layout spacing.",
            "",
            "",
            "",
            "                                    Saved note: Keyboard Shortcuts Overview",
            "",
            "                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.",
            "",
            "",
            "",
            "Focus: sidebar"
        ]

        let expected = expectedLines.joined(separator: "\n")

        #expect(sanitized.removingTrailingSpacesPerLine() == expected)
    }

    @Test("Notebook frame output stays stable across consecutive renders and selection changes")
    func testNotebookRenderStabilityAcrossFrames() {
        var app = NotebookApp()
        let initial = renderNotebook(app)

        for _ in 0..<500 {
            #expect(renderNotebook(app) == initial)
        }

        app.update(action: .selectNext)
        let afterSelection = renderNotebook(app)

        for _ in 0..<500 {
            #expect(renderNotebook(app) == afterSelection)
        }

        app.update(action: .selectPrevious)
        let backToFirst = renderNotebook(app)
        #expect(backToFirst == initial)
    }

    private func renderInitialNotebook() -> String {
        renderNotebook(NotebookApp())
    }

    private func renderNotebook(_ app: NotebookApp) -> String {
        let view = app.view(model: app)
        return view.render()
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

    func removingTrailingSpacesPerLine() -> String {
        splitLinesPreservingEmpty().map { $0.rstripSpaces() }.joined(separator: "\n")
    }

    func rstripSpaces() -> String {
        var view = self
        while view.last == " " {
            view.removeLast()
        }
        return view
    }

    func splitLinesPreservingEmpty() -> [String] {
        if isEmpty { return [""] }
        var lines: [String] = []
        lines.reserveCapacity(count / 8)

        var current = ""
        for character in self {
            if character == "\n" {
                lines.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        lines.append(current)
        return lines
    }
}

private extension Character {
    var isANSISequenceTerminator: Bool {
        switch self {
        case "a"..."z", "A"..."Z":
            return true
        default:
            return false
        }
    }
}
