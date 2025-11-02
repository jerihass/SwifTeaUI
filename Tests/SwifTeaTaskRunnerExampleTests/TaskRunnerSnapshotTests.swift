import Foundation
import Testing
@testable import SwifTeaTaskRunnerExample

@Suite(.serialized)
struct TaskRunnerSnapshotTests {

    @Test("Initial layout shows pending tasks")
    func testInitialSnapshot() {
        let snapshot = renderTaskRunner(TaskRunnerApp())
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
        var app = TaskRunnerApp()
        app.update(action: .advance)

        let snapshot = renderTaskRunner(app, time: 0)
        let processed = snapshot
            .strippingANSI()
            .removingTrailingSpacesPerLine()

        #expect(processed.contains("- Step 1/3 (ASCII)"))
        #expect(processed.contains("running (ASCII)"))
        #expect(
            processed.splitLinesPreservingEmpty()
            == TaskRunnerSnapshotFixtures.running.splitLinesPreservingEmpty()
        )
    }
}

private enum TaskRunnerSnapshotFixtures {
    static let initial = """

 SwifTea Task Runner

 ┌────────────────────────────────────────────────────────────────────────────┐
 │ Press Enter to simulate long-running steps; spinner marks the active task. │
 │                                                                            │
 │ •  1. Fetch configuration pending                                          │
 │ •  2. Run analysis pending                                                 │
 │ •  3. Write summary pending                                                │
 └────────────────────────────────────────────────────────────────────────────┘

 Task Runner Press Enter to start  [Enter] advance [f] fail [r] reset [q] quit

"""

    static let running = """

 SwifTea Task Runner

 ┌────────────────────────────────────────────────────────────────────────────┐
 │ Press Enter to simulate long-running steps; spinner marks the active task. │
 │                                                                            │
 │ -  1. Fetch configuration running (ASCII)                                  │
 │ •  2. Run analysis pending                                                 │
 │ •  3. Write summary pending                                                │
 └────────────────────────────────────────────────────────────────────────────┘

 Task Runner - Step 1/3 (ASCII)  [Enter] advance [f] fail [r] reset [q] quit

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
