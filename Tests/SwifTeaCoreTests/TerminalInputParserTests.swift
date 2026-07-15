import Testing

@testable import SwifTeaUI

struct TerminalInputParserTests {
    @Test("Key decoding is incremental, Unicode-aware, and preserves Escape")
    func keys() {
        var parser = TerminalInputParser(maximumPasteBytes: 100)
        parser.append([0x1B])
        #expect(parser.nextEvent() == nil)
        #expect(parser.nextEvent(flushIncompleteEscape: true) == .key(.escape))

        parser.append(Array("é".utf8) + [0x1B, 0x5B, 0x41, 0x08])
        #expect(parser.nextEvent() == .key(.char("é")))
        #expect(parser.nextEvent() == .key(.upArrow))
        #expect(parser.nextEvent() == .key(.backspace))
        #expect(parser.nextEvent() == nil)
    }

    @Test("Bracketed paste is one event even when markers arrive in pieces")
    func chunkedPaste() {
        var parser = TerminalInputParser(maximumPasteBytes: 100)
        parser.append([0x1B, 0x5B, 0x32])
        #expect(parser.nextEvent() == nil)
        parser.append([0x30, 0x30, 0x7E] + Array("one\ntwo".utf8) + [0x1B, 0x5B])
        #expect(parser.nextEvent() == nil)
        parser.append([0x32, 0x30, 0x31, 0x7E, 0x71])

        #expect(parser.nextEvent() == .paste("one\ntwo"))
        #expect(parser.nextEvent() == .key(.char("q")))
    }

    @Test("Oversized and malformed paste is discarded without poisoning later input")
    func rejectedPaste() {
        var parser = TerminalInputParser(maximumPasteBytes: 3)
        parser.append(pasteBytes([0x61, 0x62, 0x63, 0x64]) + [0x78])
        #expect(parser.nextEvent() == nil)
        #expect(parser.nextEvent() == .key(.char("x")))

        parser.append(pasteBytes([0xFF]) + [0x79])
        #expect(parser.nextEvent() == nil)
        #expect(parser.nextEvent() == .key(.char("y")))
    }

    @Test("Input options are safe and source-compatible by default")
    func options() {
        #expect(TerminalInputOptions().bracketedPaste == false)
        #expect(TerminalInputOptions().maximumPasteBytes == 1_048_576)
        #expect(TerminalInputOptions(bracketedPaste: true, maximumPasteBytes: -1).maximumPasteBytes == 0)
    }

    private func pasteBytes(_ payload: [UInt8]) -> [UInt8] {
        [0x1B, 0x5B, 0x32, 0x30, 0x30, 0x7E]
            + payload
            + [0x1B, 0x5B, 0x32, 0x30, 0x31, 0x7E]
    }
}
