import Foundation
import SwifTeaCore
import Testing
@testable import TaskRunnerExample

@Suite(.serialized)
struct TaskRunnerSnapshotTests {

    @Test("Initial layout shows pending tasks")
    func testInitialSnapshot() {
        let snapshot = renderTaskRunner(TaskRunnerScene())
        let processed = snapshot
            .strippingANSI()
            .removingTrailingSpacesPerLine()
        let expected = TaskRunnerSnapshotFixtures.initial
        #expect(
            processed.splitLinesPreservingEmpty()
            == expected.splitLinesPreservingEmpty()
        )
    }

    @Test("Advancing starts spinner and updates status bar")
    func testRunningSnapshot() {
        var app = TaskRunnerScene()
        app.update(action: .startSelected)
        if let firstID = app.model.stepID(at: 0) {
            app.update(action: .stepProgress(id: firstID, remaining: 3, total: 4))
        }

        let snapshot = renderTaskRunner(app, time: 0)
        let processed = snapshot
            .strippingANSI()
            .removingTrailingSpacesPerLine()
        #expect(processed.contains("1. Fetch configuration"))
        #expect(processed.contains("running (ASCII)"))
        #expect(processed.contains("• Started Fetch configuration"))
        #expect(
            processed.splitLinesPreservingEmpty()
            == TaskRunnerSnapshotFixtures.running.splitLinesPreservingEmpty()
        )
    }

    @Test("Completing first step advances progress meter and displays toast message")
    func testCompletionProgressAndToast() {
        var app = TaskRunnerScene()
        app.update(action: .startSelected)
        if let firstID = app.model.stepID(at: 0) {
            app.update(action: .stepCompleted(id: firstID, result: .success))
        }

        let snapshot = renderTaskRunner(app, time: 0)
        let processed = snapshot
            .strippingANSI()
            .removingTrailingSpacesPerLine()

        #expect(processed.contains("%"))
        #expect(processed.contains("• Completed Fetch configuration"))
    }

    @Test("Compact terminals collapse layout hints")
    func testCompactLayoutSnapshot() {
        var app = TaskRunnerScene()
        app.update(action: .startSelected)
        if let firstID = app.model.stepID(at: 0) {
            app.update(action: .stepProgress(id: firstID, remaining: 3, total: 4))
        }
        let snapshot = renderTaskRunner(
            app,
            size: TerminalSize(columns: 88, rows: 28),
            time: 0
        )
        let processed = snapshot
            .strippingANSI()
            .removingTrailingSpacesPerLine()
        #expect(
            processed.splitLinesPreservingEmpty()
            == TaskRunnerSnapshotFixtures.compact.splitLinesPreservingEmpty()
        )
    }

    @Test("Tiny terminals show fallback guidance")
    func testFallbackSnapshot() {
        let snapshot = renderTaskRunner(
            TaskRunnerScene(),
            size: TerminalSize(columns: 50, rows: 16)
        )
        let processed = snapshot
            .strippingANSI()
            .removingTrailingSpacesPerLine()
        #expect(processed.contains("Terminal too small for this demo."))
        #expect(processed.contains("Needs at least 80×24"))
    }
}

private enum TaskRunnerSnapshotFixtures {
    static let initial = """

 SwifTea Task Runner
 Select multiple steps, start them together, and watch them fan out asynchronously.

 ┌──────────────────────────────────────┐
 │ Process Queue                        │
 │                                      │
 │ 0 selected • 0 running • 0/5 done    │
 │                                      │
 │ ➤ [ ] 1. Fetch configuration pending │
 │   [ ] 2. Run analysis pending        │
 │   [ ] 3. Write summary pending       │
 │   [ ] 4. Publish artifacts pending   │
 │   [ ] 5. Notify subscribers pending  │
 └──────────────────────────────────────┘

 Space toggles selection • Enter launches all selected steps • Tasks auto-complete once their timers expire.

 Task Runner Idle – select steps to run [                    ]   0% 0 selected  [↑/↓] move [Space] toggle [Enter] run [a] all [c] clear [f] fail [r] reset [q] quit

"""

    static let running = """

 SwifTea Task Runner
 Select multiple steps, start them together, and watch them fan out asynchronously.

 ┌────────────────────────────────────────────────────────┐
 │ Process Queue                                          │
 │                                                        │
 │ 0 selected • 1 running • 0/5 done                      │
 │                                                        │
 │ ➤ [ ] 1. Fetch configuration - 25% [###         ]  25% │
 │   [ ] 2. Run analysis pending                          │
 │   [ ] 3. Write summary pending                         │
 │   [ ] 4. Publish artifacts pending                     │
 │   [ ] 5. Notify subscribers pending                    │
 └────────────────────────────────────────────────────────┘

 Space toggles selection • Enter launches all selected steps • Tasks auto-complete once their timers expire.

 Task Runner - 1 running (ASCII) [#                   ]   5% 0 selected  [↑/↓] move [Space] toggle [Enter] run [a] all [c] clear [f] fail [r] reset [q] quit • Started Fetch configuration

"""

    static let compact = """

 SwifTea Task Runner
 Select multiple steps, start them together, and watch them fan out asynchronously.

 ┌──────────────────────────────┐
 │ Process Queue                │
 │                              │
 │ 0 sel • 1 run • 0/5          │
 │                              │
 │ ➤ [ ] 1. Fetch configuration │
 │ - 25% [##        ]  25%      │
 │   [ ] 2. Run analysis        │
 │ pending                      │
 │   [ ] 3. Write summary       │
 │ pending                      │
 │   [ ] 4. Publish artifacts   │
 │ pending                      │
 │   [ ] 5. Notify subscribers  │
 │ pending                      │
 └──────────────────────────────┘

 Enter runs • Space toggles • a=all • c=clear • f=fail • r=reset • q=quit

 Task Runner - 1 running [              ]   5% Sel: 0  [↑/↓] move [Space] toggle [Enter] run [q] quit • Started Fetch configuration

"""
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
