import Foundation

public struct ZStack: TUIView {
    public typealias Body = Never

    public struct Alignment {
        public enum Horizontal {
            case leading, center, trailing
        }

        public enum Vertical {
            case top, center, bottom
        }

        let horizontal: Horizontal
        let vertical: Vertical

        public init(horizontal: Horizontal, vertical: Vertical) {
            self.horizontal = horizontal
            self.vertical = vertical
        }

        public static let center = Alignment(horizontal: .center, vertical: .center)
        public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
        public static let top = Alignment(horizontal: .center, vertical: .top)
        public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)
        public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
        public static let bottom = Alignment(horizontal: .center, vertical: .bottom)
        public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
    }

    private let alignment: Alignment
    private let layers: [any TUIView]

    public init(alignment: Alignment = .center, @TUIBuilder _ content: () -> [any TUIView]) {
        self.alignment = alignment
        self.layers = content()
    }

    public var body: Never { fatalError("ZStack has no body") }

    public func render() -> String {
        guard !layers.isEmpty else { return "" }

        let renderedLayers = layers.map { RenderedView(lines: $0.render().splitLinesPreservingEmpty()) }
        let maxWidth = max(1, renderedLayers.map { $0.maxWidth }.max() ?? 0)
        let maxHeight = max(1, renderedLayers.map { $0.height }.max() ?? 0)

        let paddedLayers: [PaddedLayer] = renderedLayers.enumerated().map { index, rendered in
            if index == 0 {
                return pad(rendered: rendered, width: maxWidth, height: maxHeight, alignment: .topLeading)
            }
            return pad(rendered: rendered, width: maxWidth, height: maxHeight, alignment: alignment)
        }

        guard var baseLayer = paddedLayers.first else { return "" }
        for overlay in paddedLayers.dropFirst() {
            for index in overlay.indices {
                let overlayLine = overlay[index]
                guard overlayLine.paints else { continue }
                baseLayer[index] = mergeLine(
                    base: baseLayer[index],
                    overlay: overlayLine
                )
            }
        }

        return baseLayer.map { $0.text }.joined(separator: "\n")
    }
}

private struct ParsedLine {
    var columns: [ANSIColumn]
    var trailing: String
}

private struct PaddedLine {
    var text: String
    var coverage: [Bool]
    var parsed: ParsedLine
    var paints: Bool
}

private typealias PaddedLayer = [PaddedLine]

private func pad(rendered: RenderedView, width: Int, height: Int, alignment: ZStack.Alignment) -> PaddedLayer {
    var padded: PaddedLayer = []
    padded.reserveCapacity(height)

    for (index, line) in rendered.lines.enumerated() {
        let currentWidth = index < rendered.widths.count ? rendered.widths[index] : HStack.visibleWidth(of: line)
        let (paddedLine, coverage) = padLine(
            line: line,
            lineWidth: currentWidth,
            width: width,
            horizontal: alignment.horizontal
        )
        let parsed = parseLine(paddedLine)
        padded.append(PaddedLine(
            text: paddedLine,
            coverage: coverage,
            parsed: parsed,
            paints: coverage.contains(true) || !parsed.trailing.isEmpty
        ))
    }

    let blankLine = String(repeating: " ", count: width)
    let blankCoverage = Array(repeating: false, count: width)
    let blankParsed = parseLine(blankLine)
    let extra = height - padded.count
    if extra > 0 {
        let blanks = Array(repeating: PaddedLine(text: blankLine, coverage: blankCoverage, parsed: blankParsed, paints: false), count: extra)
        switch alignment.vertical {
        case .top:
            padded.append(contentsOf: blanks)
        case .bottom:
            padded = blanks + padded
        case .center:
            let leading = extra / 2
            let trailing = extra - leading
            padded = Array(blanks.prefix(leading)) + padded + Array(blanks.suffix(trailing))
        }
    } else if extra < 0 {
        padded = Array(padded.prefix(height))
    }

    if padded.isEmpty {
        padded = Array(
            repeating: PaddedLine(text: blankLine, coverage: blankCoverage, parsed: blankParsed, paints: false),
            count: height
        )
    }

    return padded
}

private func padLine(
    line: String,
    lineWidth: Int,
    width: Int,
    horizontal: ZStack.Alignment.Horizontal
) -> (String, [Bool]) {
    if lineWidth >= width {
        let coverage = Array(repeating: true, count: width)
        return (line, coverage)
    }
    let padding = width - lineWidth
    let spaces: (leading: Int, trailing: Int) = {
        switch horizontal {
        case .leading: return (0, padding)
        case .trailing: return (padding, 0)
        case .center:
            let leading = padding / 2
            return (leading, padding - leading)
        }
    }()
    let padded = String(repeating: " ", count: spaces.leading) + line + String(repeating: " ", count: spaces.trailing)
    let coverage = Array(repeating: false, count: spaces.leading) + Array(repeating: true, count: lineWidth) + Array(repeating: false, count: spaces.trailing)
    return (padded, coverage)
}

private enum ANSIToken {
    case escape(String)
    case char(Character)
}

private struct ANSIColumn {
    var prefix: String
    var char: Character
}

private func tokenize(_ string: String) -> [ANSIToken] {
    var tokens: [ANSIToken] = []
    let characters = Array(string)
    var index = 0
    while index < characters.count {
        let ch = characters[index]
        if ch == "\u{001B}" {
            var sequence = String(ch)
            index += 1
            while index < characters.count {
                let next = characters[index]
                sequence.append(next)
                if next.isANSISequenceTerminator {
                    index += 1
                    break
                }
                index += 1
            }
            tokens.append(.escape(sequence))
        } else {
            tokens.append(.char(ch))
            index += 1
        }
    }
    return tokens
}

private func columns(from string: String) -> ([ANSIColumn], String) {
    var columns: [ANSIColumn] = []
    var prefix = ""
    for token in tokenize(string) {
        switch token {
        case .escape(let seq):
            prefix += seq
        case .char(let ch):
            columns.append(ANSIColumn(prefix: prefix, char: ch))
            prefix = ""
        }
    }
    return (columns, prefix)
}

private func parseLine(_ string: String) -> ParsedLine {
    let (columns, trailing) = columns(from: string)
    return ParsedLine(columns: columns, trailing: trailing)
}

private func mergeLine(base: PaddedLine, overlay: PaddedLine) -> PaddedLine {
    let baseColumns = base.parsed.columns
    let overlayColumns = overlay.parsed.columns
    let overlayTrailing = overlay.parsed.trailing
    let baseTrailing = base.parsed.trailing
    let coverage = overlay.coverage

    let width = max(baseColumns.count, overlayColumns.count, coverage.count)
    var result = ""
    var overlayIsActive = false
    var appendedOverlayTrailing = false
    var needsBaseStateInjection = false
    var baseState = ""

    for index in 0..<width {
        let baseColumn = index < baseColumns.count ? baseColumns[index] : ANSIColumn(prefix: "", char: " ")
        let overlayColumn = index < overlayColumns.count ? overlayColumns[index] : nil
        let overlayCovers = overlayColumn != nil && index < coverage.count && coverage[index]

        if overlayIsActive && !overlayCovers {
            if let overlayColumn, !overlayColumn.prefix.isEmpty {
                result += overlayColumn.prefix
            } else if !overlayTrailing.isEmpty {
                result += overlayTrailing
                appendedOverlayTrailing = true
            }
            overlayIsActive = false
            needsBaseStateInjection = true
        }

        if overlayCovers, let overlayColumn {
            overlayIsActive = true
            needsBaseStateInjection = false
            result += overlayColumn.prefix
            result.append(overlayColumn.char)
        } else {
            if needsBaseStateInjection, !baseState.isEmpty {
                result += baseState
                needsBaseStateInjection = false
            }
            result += baseColumn.prefix
            result.append(baseColumn.char)
        }

        baseState = applyANSIPrefix(baseColumn.prefix, to: baseState)
    }

    if overlayIsActive && !overlayTrailing.isEmpty {
        result += overlayTrailing
        appendedOverlayTrailing = true
    }

    if !appendedOverlayTrailing {
        result += overlayTrailing
    }
    result += baseTrailing
    let parsed = parseLine(result)
    return PaddedLine(
        text: result,
        coverage: Array(repeating: true, count: parsed.columns.count),
        parsed: parsed,
        paints: !parsed.columns.isEmpty || !parsed.trailing.isEmpty
    )
}

private func applyANSIPrefix(_ prefix: String, to currentState: String) -> String {
    guard !prefix.isEmpty else { return currentState }
    var state = currentState
    var inEscape = false
    var sequence = ""

    for character in prefix {
        if !inEscape {
            if character == "\u{001B}" {
                inEscape = true
                sequence = String(character)
            }
            continue
        }

        sequence.append(character)
        if character.isANSISequenceTerminator {
            if sequence == ANSIColor.reset.rawValue {
                state = ""
            } else {
                state += sequence
            }
            inEscape = false
            sequence = ""
        }
    }

    return state
}
