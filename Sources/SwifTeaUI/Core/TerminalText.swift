import Foundation

public enum TerminalText {
    /// Returns terminal-safe literal text by replacing control scalars with U+FFFD.
    ///
    /// This transform intentionally operates on Unicode scalars rather than
    /// graphemes so every rejected C0, DEL, or C1 scalar has one visible
    /// replacement. Line feeds are retained only for multiline renderers.
    static func literal(_ string: String, preservingLineFeeds: Bool) -> String {
        var result = ""
        result.reserveCapacity(string.utf8.count)

        for scalar in string.unicodeScalars {
            let value = scalar.value
            if value == 0x0A, preservingLineFeeds {
                result.unicodeScalars.append(scalar)
            } else if value < 0x20 || (0x7F...0x9F).contains(value) {
                result.unicodeScalars.append("\u{FFFD}")
            } else {
                result.unicodeScalars.append(scalar)
            }
        }

        return result
    }

    /// Maps a cursor expressed in authored grapheme offsets into a literal-safe
    /// rendered string. Scalar replacement can expand a single grapheme (for
    /// example CRLF), so editors must not reuse the authored offset directly.
    static func literalCursorOffset(
        in string: String,
        characterOffset: Int,
        preservingLineFeeds: Bool
    ) -> Int {
        let clampedOffset = max(0, min(characterOffset, string.count))
        let boundary = string.index(string.startIndex, offsetBy: clampedOffset)
        return literal(String(string[..<boundary]), preservingLineFeeds: preservingLineFeeds).count
    }

    public static func visibleWidth(of string: String) -> Int {
        tokens(in: string).reduce(into: 0) { width, token in
            if case .grapheme(_, let cells) = token { width += cells }
        }
    }

    public static func cellWidth(of character: Character) -> Int {
        let scalars = character.unicodeScalars
        guard !scalars.isEmpty else { return 0 }

        if scalars.allSatisfy({ isZeroWidth($0.value) }) { return 0 }
        if scalars.contains(where: { $0.value == 0xFE0F || $0.value == 0x200D }) { return 2 }
        if scalars.contains(where: { isWide($0.value) }) { return 2 }
        return 1
    }

    static func fittedLine(_ line: String, to width: Int, padded: Bool = true) -> String {
        guard width > 0 else { return "" }

        var result = ""
        var used = 0
        var sawEscape = false
        for token in tokens(in: line) {
            switch token {
            case .escape(let sequence):
                sawEscape = true
                result += sequence
            case .grapheme(let character, let cells):
                guard used + cells <= width else {
                    if sawEscape, !result.hasSuffix(ANSIColor.reset.rawValue) {
                        result += ANSIColor.reset.rawValue
                    }
                    return padded ? result + String(repeating: " ", count: width - used) : result
                }
                result.append(character)
                used += cells
            }
        }

        guard padded, used < width else { return result }
        if sawEscape, !result.hasSuffix(ANSIColor.reset.rawValue) {
            result += ANSIColor.reset.rawValue
        }
        result += String(repeating: " ", count: width - used)
        return result
    }

    static func sliceLine(_ line: String, offset: Int, width: Int) -> String {
        guard width > 0 else { return "" }
        let lower = max(0, offset)
        let upper = lower + width
        var position = 0
        var outputWidth = 0
        var result = ""
        var pendingEscapes = ""
        var emittedStyledContent = false

        for token in tokens(in: line) {
            switch token {
            case .escape(let sequence):
                pendingEscapes += sequence
            case .grapheme(let character, let cells):
                let range = position..<(position + cells)
                defer { position += cells }
                guard range.upperBound > lower, range.lowerBound < upper else { continue }

                let fullyVisible = range.lowerBound >= lower && range.upperBound <= upper
                if fullyVisible {
                    if !pendingEscapes.isEmpty {
                        result += pendingEscapes
                        pendingEscapes = ""
                        emittedStyledContent = true
                    }
                    result.append(character)
                    outputWidth += cells
                } else {
                    let overlap = min(range.upperBound, upper) - max(range.lowerBound, lower)
                    result += String(repeating: " ", count: max(0, overlap))
                    outputWidth += max(0, overlap)
                }
            }
        }

        if emittedStyledContent, !result.hasSuffix(ANSIColor.reset.rawValue) {
            result += ANSIColor.reset.rawValue
        }
        if outputWidth < width {
            result += String(repeating: " ", count: width - outputWidth)
        }
        return result
    }

    private enum Token {
        case escape(String)
        case grapheme(Character, cells: Int)
    }

    private static func tokens(in string: String) -> [Token] {
        var result: [Token] = []
        var index = string.startIndex

        while index < string.endIndex {
            let character = string[index]
            if character == "\u{001B}" {
                var sequence = String(character)
                index = string.index(after: index)
                while index < string.endIndex {
                    let next = string[index]
                    sequence.append(next)
                    index = string.index(after: index)
                    if next.isANSISequenceTerminator { break }
                }
                result.append(.escape(sequence))
            } else {
                result.append(.grapheme(character, cells: cellWidth(of: character)))
                index = string.index(after: index)
            }
        }
        return result
    }

    private static func isZeroWidth(_ value: UInt32) -> Bool {
        value == 0x200B || value == 0x200C || value == 0x200D || value == 0x2060
            || (0x0300...0x036F).contains(value)
            || (0x1AB0...0x1AFF).contains(value)
            || (0x1DC0...0x1DFF).contains(value)
            || (0x20D0...0x20FF).contains(value)
            || (0xFE00...0xFE0F).contains(value)
            || (0xFE20...0xFE2F).contains(value)
            || (0xE0100...0xE01EF).contains(value)
    }

    private static func isWide(_ value: UInt32) -> Bool {
        value == 0x2329 || value == 0x232A
            || (0x1100...0x115F).contains(value)
            || (0x2E80...0x303E).contains(value)
            || (0x3040...0xA4CF).contains(value)
            || (0xAC00...0xD7A3).contains(value)
            || (0xF900...0xFAFF).contains(value)
            || (0xFE10...0xFE19).contains(value)
            || (0xFE30...0xFE6F).contains(value)
            || (0xFF00...0xFF60).contains(value)
            || (0xFFE0...0xFFE6).contains(value)
            || (0x1F1E6...0x1F1FF).contains(value)
            || (0x1F300...0x1FAFF).contains(value)
            || (0x20000...0x3FFFD).contains(value)
    }
}
