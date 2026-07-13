import Testing

@testable import SwifTeaUI

@Suite("Rich text")
struct RichTextTests {
    @Test("Styled spans wrap as one paragraph and reapply styles")
    func styledWrapping() {
        let view = RichText(width: 16) {
            TextSpan("Attack").foregroundColor(.yellow).bold()
            TextSpan(" Draw one card, then discard one card.")
        }

        let rendered = view.render()
        #expect(rendered.removingANSI == "Attack Draw one\ncard, then\ndiscard one\ncard.")
        #expect(rendered.contains(ANSIColor.yellow.rawValue))
        #expect(rendered.contains("\u{001B}[1m"))
        #expect(
            rendered.split(separator: "\n").allSatisfy { TerminalText.visibleWidth(of: String($0)) <= 16 }
        )
    }

    @Test("Inline groups move intact to the next line")
    func atomicGroup() {
        let view = RichText(width: 10) {
            TextSpan("12345 ")
            InlineGroup {
                TextSpan("[")
                TextSpan("Attack").bold()
                TextSpan("]")
            }
            TextSpan(" now")
        }

        #expect(view.render().removingANSI == "12345\n[Attack]\nnow")
    }

    @Test("Powerline capsules preserve independent foreground and background styles")
    func powerlineCapsule() {
        let view = RichText(width: 20) {
            InlineGroup {
                TextSpan("").foregroundColor(.yellow)
                TextSpan("Attack").foregroundColor(.black).backgroundColor(.yellow).bold()
                TextSpan("").foregroundColor(.yellow)
            }
            TextSpan(" Draw 1.")
        }

        let rendered = view.render()
        #expect(rendered.removingANSI == "Attack Draw 1.")
        #expect(TerminalText.visibleWidth(of: rendered) == 16)
        #expect(rendered.contains(ANSIColor.yellow.backgroundCode))
    }

    @Test("Authored newlines, blank lines, and cross-span words are preserved")
    func authoredLines() {
        let view = RichText(width: 6) {
            TextSpan("ab").bold()
            TextSpan("cdef\n\nnext")
        }

        #expect(view.render().removingANSI == "abcdef\n\nnext")
    }

    @Test("Oversized words split only at grapheme boundaries")
    func oversizedWord() {
        let rendered = RichText(width: 4) {
            TextSpan("AB界CD")
        }.render()

        #expect(rendered == "AB界\nCD")
        #expect(
            rendered.split(separator: "\n").allSatisfy { TerminalText.visibleWidth(of: String($0)) <= 4 })
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
