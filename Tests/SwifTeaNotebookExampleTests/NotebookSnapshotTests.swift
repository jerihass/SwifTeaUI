import Testing
@testable import SwifTeaNotebookExample
import SwifTeaCore

struct NotebookSnapshotTests {

    @Test("Initial layout renders expected snapshot")
    func testInitialLayoutSnapshot() {
        let snapshot = renderInitialNotebook()
        let sanitized = snapshot.strippingANSI()

        #expect(snapshot.contains(ANSIColor.cyan.rawValue + ">▌ Welcome" + ANSIColor.reset.rawValue))

        let normalized = sanitized.removingTrailingSpacesPerLine()

        #expect(normalized.contains("SwifTea Notebook"))
        #expect(normalized.contains("[Tab] next focus"))
        #expect(normalized.contains("Notes"))
        #expect(normalized.contains("Editor"))
        #expect(normalized.contains("Saved note: Welcome"))
        #expect(normalized.contains("Focus: sidebar"))
    }

    private func renderInitialNotebook() -> String {
        let app = NotebookApp()
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
