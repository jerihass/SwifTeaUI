import Testing

@testable import SwifTeaUI

@Suite("Proposed layout")
struct ProposedLayoutTests {
    @Test("Composed custom views propagate proposed width without overrides")
    func composedCompatibility() {
        struct Card: TUIView {
            var body: some TUIView {
                Border(padding: 0, RichText { TextSpan("one two three four") })
            }
        }

        let rendered = Card().render(
            in: RenderContext(proposedSize: ProposedViewSize(width: 10))
        )

        #expect(rendered.removingANSI == "┌───────┐\n│one two│\n│three  │\n│four   │\n└───────┘")
    }

    @Test("Legacy primitive views remain source compatible")
    func primitiveCompatibility() {
        struct Legacy: TUIView {
            typealias Body = Never
            var body: Never { fatalError() }
            func render() -> String { "legacy" }
        }

        #expect(
            Legacy().render(in: RenderContext(proposedSize: ProposedViewSize(width: 3)))
                == "legacy"
        )
    }

    @Test("HStack allocates remaining width to explicitly flexible children")
    func flexibleAllocation() {
        let view = HStack(spacing: 1) {
            Text("List")
            Border(padding: 0, RichText { TextSpan("one two three") })
                .frame(width: .flexible(minimum: 6))
        }

        let rendered = view.render(
            in: RenderContext(proposedSize: ProposedViewSize(width: 16))
        )
        let lines = rendered.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        #expect(lines.allSatisfy { TerminalText.visibleWidth(of: $0) == 16 })
        #expect(rendered.removingANSI.contains("│one two  │"))
        #expect(rendered.removingANSI.contains("│three    │"))
    }

    @Test("Fixed frames clip wide text by terminal cell width")
    func fixedFrame() {
        let rendered = Text("A界B").frame(width: .fixed(3)).render()
        #expect(rendered == "A界")
        #expect(TerminalText.visibleWidth(of: rendered) == 3)
    }
}

extension String {
    fileprivate var removingANSI: String {
        var result = ""
        var inEscape = false
        for character in self {
            if inEscape {
                if character.isANSISequenceTerminator { inEscape = false }
            } else if character == "\u{001B}" {
                inEscape = true
            } else {
                result.append(character)
            }
        }
        return result
    }
}
