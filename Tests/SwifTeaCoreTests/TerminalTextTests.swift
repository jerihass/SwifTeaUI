import Testing

@testable import SwifTeaUI

@Suite("Terminal text measurement")
struct TerminalTextTests {
    @Test("ANSI sequences have no width and Powerline glyphs occupy one cell")
    func styledAndPowerlineWidth() {
        let styled = ANSIColor.yellow.rawValue + "Attack" + ANSIColor.reset.rawValue
        #expect(TerminalText.visibleWidth(of: styled) == 8)
    }

    @Test("Wide and combining graphemes use terminal cell widths")
    func unicodeWidths() {
        #expect(TerminalText.visibleWidth(of: "界") == 2)
        #expect(TerminalText.visibleWidth(of: "e\u{301}") == 1)
        #expect(TerminalText.visibleWidth(of: "👩‍💻") == 2)
        #expect(TerminalText.visibleWidth(of: "🇺🇸") == 2)
    }

    @Test("Fitting never emits a partial wide grapheme")
    func fittingWideText() {
        #expect(TerminalText.fittedLine("A界B", to: 3) == "A界")
        #expect(TerminalText.fittedLine("A界B", to: 2) == "A ")
    }

    @Test("Slicing replaces a partially visible wide grapheme with a cell")
    func slicingWideText() {
        #expect(TerminalText.sliceLine("A界B", offset: 1, width: 2) == "界")
        #expect(TerminalText.sliceLine("A界B", offset: 2, width: 2) == " B")
    }
}
