import Foundation
import Testing
@testable import SwifTeaNotebookExample
import SwifTeaCore

private let focusHighlightPrefix = ANSIColor.cyan.rawValue + "\u{001B}[1m"

@Suite(.serialized)
struct NotebookSnapshotTests {

    private func expectSidebarFocus(in snapshot: String) {
        let notesHighlight = focusHighlightPrefix + "Notes"
        let editorHighlight = focusHighlightPrefix + "Editor"
        #expect(snapshot.contains(notesHighlight))
        #expect(!snapshot.contains(editorHighlight))
    }

    private func expectEditorFocus(in snapshot: String) {
        let editorHighlight = focusHighlightPrefix + "Editor"
        let notesHighlight = focusHighlightPrefix + "Notes"
        #expect(snapshot.contains(editorHighlight))
        #expect(!snapshot.contains(notesHighlight))
    }

    @Test("Initial layout renders expected snapshot")
    func testInitialLayoutSnapshot() {
        let snapshot = assertSnapshot(
            contains: ANSIColor.cyan.rawValue + ">▌ Welcome to SwifTeaUI" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.initial
        )
        expectSidebarFocus(in: snapshot)
    }

    @Test("Notebook stacks panes when width constrained")
    func testStackedLayoutSnapshot() {
        let snapshot = assertSnapshot(
            expected: NotebookSnapshotFixtures.stacked,
            size: TerminalSize(columns: 110, rows: 40)
        )
        expectSidebarFocus(in: snapshot)
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
        let snapshot = assertSnapshot(
            mutate: { $0.update(action: .setFocus(.editorTitle)) },
            contains: ANSIColor.cyan.rawValue + "Title:" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.titleFocus
        )
        expectEditorFocus(in: snapshot)
    }

    @Test("Body field focus snapshot shows cursor in body")
    func testBodyFieldFocusSnapshot() {
        let snapshot = assertSnapshot(
            mutate: { $0.update(action: .setFocus(.editorBody)) },
            contains: ANSIColor.cyan.rawValue + "Body:" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.bodyFocus
        )
        expectEditorFocus(in: snapshot)
    }

    @Test("Sidebar selection snapshot highlights second note")
    func testSidebarSelectionSnapshot() {
        let snapshot = assertSnapshot(
            mutate: { $0.update(action: .selectNext) },
            contains: ANSIColor.cyan.rawValue + ">▌ Keyboard Shortcuts Overview" + ANSIColor.reset.rawValue,
            expected: NotebookSnapshotFixtures.secondNote
        )
        expectSidebarFocus(in: snapshot)
    }

    @Test("Notebook frame output stays stable across consecutive renders and selection changes")
    func testNotebookRenderStabilityAcrossFrames() {
        var app = NotebookScene()
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

@discardableResult
private func assertSnapshot(
    mutate: (inout NotebookScene) -> Void = { _ in },
    contains substring: String? = nil,
    expected expectedSnapshot: String,
    size overrideSize: TerminalSize? = nil
) -> String {
    var app = NotebookScene()
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
    return snapshot
}

private enum NotebookSnapshotFixtures {
    static let initial = """
SwifTea Notebook



┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                                      │
│  Notes                             Editor                                                                            │
│  >▌ Welcome to SwifTeaUI                                                                                             │
│     Keyboard Shortcuts Overview    Title:                                                                            │
│     Ideas and Enhancements                                                                                           │
│                                    Welcome to SwifTeaUI                                                              │
│                                                                                                                      │
│                                    Body:                                                                             │
│                                                                                                                      │
│                                    Use Tab to focus fields on the right, Shift+Tab to return                         │
│                                    here. This long introduction should stay visible even when                        │
│                                    the bottom of the screen is busy.                                                 │
│                                                                                                                      │
│                                                                                                                      │
│                                                                                                                      │
│                                    Saved note: Welcome to SwifTeaUI                                                  │
│                                                                                                                      │
│                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.  │
│                                                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘



Focus: sidebar  Enter edit  ↑/↓ choose  Tab editor
"""

    static let titleFocus = """
SwifTea Notebook



┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                                      │
│  Notes                             Editor                                                                            │
│  >  Welcome to SwifTeaUI                                                                                             │
│     Keyboard Shortcuts Overview    Title:                                                                            │
│     Ideas and Enhancements                                                                                           │
│                                    Welcome to SwifTeaUI|                                                             │
│                                                                                                                      │
│                                    Body:                                                                             │
│                                                                                                                      │
│                                    Use Tab to focus fields on the right, Shift+Tab to return                         │
│                                    here. This long introduction should stay visible even when                        │
│                                    the bottom of the screen is busy.                                                 │
│                                                                                                                      │
│                                                                                                                      │
│                                                                                                                      │
│                                    Saved note: Welcome to SwifTeaUI                                                  │
│                                                                                                                      │
│                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.  │
│                                                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘



Focus: editor.title  Enter save  Tab body  Esc sidebar
"""

    static let bodyFocus = """
SwifTea Notebook



┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                                      │
│  Notes                             Editor                                                                            │
│  >  Welcome to SwifTeaUI                                                                                             │
│     Keyboard Shortcuts Overview    Title:                                                                            │
│     Ideas and Enhancements                                                                                           │
│                                    Welcome to SwifTeaUI                                                              │
│                                                                                                                      │
│                                    Body:                                                                             │
│                                                                                                                      │
│                                    Use Tab to focus fields on the right, Shift+Tab to return                         │
│                                    here. This long introduction should stay visible even when                        │
│                                    the bottom of the screen is busy.|                                                │
│                                                                                                                      │
│                                                                                                                      │
│                                                                                                                      │
│                                    Saved note: Welcome to SwifTeaUI                                                  │
│                                                                                                                      │
│                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.  │
│                                                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘



Focus: editor.body  Enter save  Shift+Tab title  Esc sidebar
"""

    static let secondNote = """
SwifTea Notebook



┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                                      │
│  Notes                             Editor                                                                            │
│     Welcome to SwifTeaUI                                                                                             │
│  >▌ Keyboard Shortcuts Overview    Title:                                                                            │
│     Ideas and Enhancements                                                                                           │
│                                    Keyboard Shortcuts Overview                                                       │
│                                                                                                                      │
│                                    Body:                                                                             │
│                                                                                                                      │
│                                    ↑/↓ move between notes when the sidebar is focused. Enter                         │
│                                    while editing the body saves. Longer descriptions ensure we                       │
│                                    validate vertical layout spacing.                                                 │
│                                                                                                                      │
│                                                                                                                      │
│                                                                                                                      │
│                                    Saved note: Keyboard Shortcuts Overview                                           │
│                                                                                                                      │
│                                    Status: Tab to edit the welcome note and confirm longer content renders cleanly.  │
│                                                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘



Focus: sidebar  Enter edit  ↑/↓ choose  Tab editor
"""

    static let resizePrompt = """
SwifTea Notebook



┌────────────────────────────────┐
│ Terminal too small             │
│                                │
│ Minimum required: 90×32        │
│                                │
│ Current: 80×20                 │
│                                │
│ Resize the window to continue. │
└────────────────────────────────┘
"""

    static let stacked = """
SwifTea Notebook



┌────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                    │
│  Notes                                                                             │
│  >▌ Welcome to SwifTeaUI                                                           │
│     Keyboard Shortcuts Overview                                                    │
│     Ideas and Enhancements                                                         │
│                                                                                    │
│                                                                                    │
│                                                                                    │
│  Editor                                                                            │
│                                                                                    │
│  Title:                                                                            │
│                                                                                    │
│  Welcome to SwifTeaUI                                                              │
│                                                                                    │
│  Body:                                                                             │
│                                                                                    │
│  Use Tab to focus fields on the right, Shift+Tab to return here. This              │
│  long introduction should stay visible even when the bottom of the                 │
│  screen is busy.                                                                   │
│                                                                                    │
│                                                                                    │
│                                                                                    │
│  Saved note: Welcome to SwifTeaUI                                                  │
│                                                                                    │
│  Status: Tab to edit the welcome note and confirm longer content renders cleanly.  │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘



Focus: sidebar  Enter edit  ↑/↓ choose  Tab editor
"""
}
