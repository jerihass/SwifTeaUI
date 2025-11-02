import Foundation
import Testing
@testable import SwifTeaNotebookExample
import SwifTeaCore

struct NotebookSnapshotTests {

    @Test("Initial layout renders expected snapshot")
    func testInitialLayoutSnapshot() {
        assertSnapshot(
            contains: ANSIColor.cyan.rawValue + ">▌ Welcome to SwifTeaUI" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.initial
        )
    }

    @Test("Notebook renders resize prompt when terminal too small")
    func testResizePromptSnapshot() {
        assertSnapshot(
            expected: NotebookSnapshotFixtures.resizePrompt,
            size: TerminalSize(columns: 80, rows: 20)
        )
    }

    @Test("Title field focus snapshot shows cursor in title")
    func testTitleFieldFocusSnapshot() {
        assertSnapshot(
            mutate: { $0.update(action: .setFocus(.editorTitle)) },
            contains: ANSIColor.cyan.rawValue + "Title:" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.titleFocus
        )
    }

    @Test("Body field focus snapshot shows cursor in body")
    func testBodyFieldFocusSnapshot() {
        assertSnapshot(
            mutate: { $0.update(action: .setFocus(.editorBody)) },
            contains: ANSIColor.cyan.rawValue + "Body:" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.bodyFocus
        )
    }

    @Test("Sidebar selection snapshot highlights second note")
    func testSidebarSelectionSnapshot() {
        assertSnapshot(
            mutate: { $0.update(action: .selectNext) },
            contains: ANSIColor.cyan.rawValue + ">▌ Keyboard Shortcuts Overview" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.secondNote
        )
    }

    @Test("Notebook frame output stays stable across consecutive renders and selection changes")
    func testNotebookRenderStabilityAcrossFrames() {
        var app = NotebookApp()
        let initial = renderNotebook(app)

        for _ in 0..<5 {
            #expect(renderNotebook(app) == initial)
        }

        app.update(action: .selectNext)
        let afterSelection = renderNotebook(app)

        for _ in 0..<5 {
            #expect(renderNotebook(app) == afterSelection)
        }

        app.update(action: .selectPrevious)
        let backToFirst = renderNotebook(app)
        #expect(backToFirst == initial)
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

private func assertSnapshot(
    mutate: (inout NotebookApp) -> Void = { _ in },
    contains substring: String? = nil,
    expected expectedSnapshot: String,
    size overrideSize: TerminalSize? = nil
) {
    var app = NotebookApp()
    mutate(&app)

    let snapshot = renderNotebook(
        app,
        size: overrideSize ?? defaultSnapshotSize
    )
    if let substring {
        #expect(snapshot.contains(substring))
    }

    let processed = snapshot
        .strippingANSI()
        .removingTrailingSpacesPerLine()

    let expectedProcessed = expectedSnapshot
        .removingTrailingSpacesPerLine()

    #expect(processed == expectedProcessed)
}

private enum NotebookSnapshotFixtures {
    static let initial = """
SwifTea Notebook



┌────────────────────────────────┐      ┌──────────────────────────────────────────────────────────────────────────────────┐
│ Notes                          │      │ Editor                                                                           │
│ >▌ Welcome to SwifTeaUI        │      │                                                                                  │
│    Keyboard Shortcuts Overview │      │ Title:                                                                           │
│    Ideas and Enhancements      │      │                                                                                  │
└────────────────────────────────┘      │ Welcome to SwifTeaUI                                                             │
                                        │                                                                                  │
                                        │ Body:                                                                            │
                                        │                                                                                  │
                                        │ Use Tab to focus fields on the right, Shift+Tab to return                        │
                                        │ here. This long introduction should stay visible even when                       │
                                        │ the bottom of the screen is busy.                                                │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │ Saved note: Welcome to SwifTeaUI                                                 │
                                        │                                                                                  │
                                        │ Status: Tab to edit the welcome note and confirm longer content renders cleanly. │
                                        └──────────────────────────────────────────────────────────────────────────────────┘



Focus: sidebar  Tab next  Shift+Tab prev  ↑/↓ choose note  Enter save
"""

    static let titleFocus = """
SwifTea Notebook



┌────────────────────────────────┐      ┌──────────────────────────────────────────────────────────────────────────────────┐
│ Notes                          │      │ Editor                                                                           │
│ >  Welcome to SwifTeaUI        │      │                                                                                  │
│    Keyboard Shortcuts Overview │      │ Title:                                                                           │
│    Ideas and Enhancements      │      │                                                                                  │
└────────────────────────────────┘      │ Welcome to SwifTeaUI|                                                            │
                                        │                                                                                  │
                                        │ Body:                                                                            │
                                        │                                                                                  │
                                        │ Use Tab to focus fields on the right, Shift+Tab to return                        │
                                        │ here. This long introduction should stay visible even when                       │
                                        │ the bottom of the screen is busy.                                                │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │ Saved note: Welcome to SwifTeaUI                                                 │
                                        │                                                                                  │
                                        │ Status: Tab to edit the welcome note and confirm longer content renders cleanly. │
                                        └──────────────────────────────────────────────────────────────────────────────────┘



Focus: editor.title  Tab next  Shift+Tab prev  ↑/↓ choose note  Enter save
"""

    static let bodyFocus = """
SwifTea Notebook



┌────────────────────────────────┐      ┌──────────────────────────────────────────────────────────────────────────────────┐
│ Notes                          │      │ Editor                                                                           │
│ >  Welcome to SwifTeaUI        │      │                                                                                  │
│    Keyboard Shortcuts Overview │      │ Title:                                                                           │
│    Ideas and Enhancements      │      │                                                                                  │
└────────────────────────────────┘      │ Welcome to SwifTeaUI                                                             │
                                        │                                                                                  │
                                        │ Body:                                                                            │
                                        │                                                                                  │
                                        │ Use Tab to focus fields on the right, Shift+Tab to return                        │
                                        │ here. This long introduction should stay visible even when                       │
                                        │ the bottom of the screen is busy.|                                               │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │ Saved note: Welcome to SwifTeaUI                                                 │
                                        │                                                                                  │
                                        │ Status: Tab to edit the welcome note and confirm longer content renders cleanly. │
                                        └──────────────────────────────────────────────────────────────────────────────────┘



Focus: editor.body  Tab next  Shift+Tab prev  ↑/↓ choose note  Enter save
"""

    static let secondNote = """
SwifTea Notebook



┌────────────────────────────────┐      ┌──────────────────────────────────────────────────────────────────────────────────┐
│ Notes                          │      │ Editor                                                                           │
│    Welcome to SwifTeaUI        │      │                                                                                  │
│ >▌ Keyboard Shortcuts Overview │      │ Title:                                                                           │
│    Ideas and Enhancements      │      │                                                                                  │
└────────────────────────────────┘      │ Keyboard Shortcuts Overview                                                      │
                                        │                                                                                  │
                                        │ Body:                                                                            │
                                        │                                                                                  │
                                        │ ↑/↓ move between notes when the sidebar is focused. Enter                        │
                                        │ while editing the body saves. Longer descriptions ensure we                      │
                                        │ validate vertical layout spacing.                                                │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │                                                                                  │
                                        │ Saved note: Keyboard Shortcuts Overview                                          │
                                        │                                                                                  │
                                        │ Status: Tab to edit the welcome note and confirm longer content renders cleanly. │
                                        └──────────────────────────────────────────────────────────────────────────────────┘



Focus: sidebar  Tab next  Shift+Tab prev  ↑/↓ choose note  Enter save
"""

    static let resizePrompt = """
SwifTea Notebook



┌────────────────────────────────┐
│ Terminal too small             │
│                                │
│ Minimum required: 125×24       │
│                                │
│ Current: 80×20                 │
│                                │
│ Resize the window to continue. │
└────────────────────────────────┘
"""
}
