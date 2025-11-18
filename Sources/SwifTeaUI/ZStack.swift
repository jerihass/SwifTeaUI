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

        let renderedLayers = layers.map { $0.render().splitLinesPreservingEmpty() }
        let maxWidth = max(1, renderedLayers.map { lines in
            lines.map { HStack.visibleWidth(of: $0) }.max() ?? 0
        }.max() ?? 0)
        let maxHeight = max(1, renderedLayers.map { $0.count }.max() ?? 0)

        let paddedLayers = renderedLayers.enumerated().map { index, lines in
            if index == 0 {
                return pad(lines: lines, width: maxWidth, height: maxHeight, alignment: .topLeading)
            }
            return pad(lines: lines, width: maxWidth, height: maxHeight, alignment: alignment)
        }

        guard let baseLayer = paddedLayers.first else { return "" }
        var canvas = baseLayer.lines
        for layer in paddedLayers.dropFirst() {
            for index in layer.lines.indices {
                canvas[index] = mergeLine(base: canvas[index], overlay: layer.lines[index], coverage: layer.coverage[index])
            }
        }

        return canvas.joined(separator: "\n")
    }
}

private struct PaddedLayer {
    var lines: [String]
    var coverage: [[Bool]]
}

private func pad(lines: [String], width: Int, height: Int, alignment: ZStack.Alignment) -> PaddedLayer {
    var paddedLines: [String] = []
    var coverageRows: [[Bool]] = []

    for line in lines {
        let (padded, coverage) = padLine(line: line, width: width, horizontal: alignment.horizontal)
        paddedLines.append(padded)
        coverageRows.append(coverage)
    }

    let blankLine = String(repeating: " ", count: width)
    let blankCoverage = Array(repeating: false, count: width)
    let extra = height - paddedLines.count
    if extra > 0 {
        switch alignment.vertical {
        case .top:
            paddedLines.append(contentsOf: Array(repeating: blankLine, count: extra))
            coverageRows.append(contentsOf: Array(repeating: blankCoverage, count: extra))
        case .bottom:
            paddedLines = Array(repeating: blankLine, count: extra) + paddedLines
            coverageRows = Array(repeating: blankCoverage, count: extra) + coverageRows
        case .center:
            let leading = extra / 2
            let trailing = extra - leading
            paddedLines = Array(repeating: blankLine, count: leading) + paddedLines + Array(repeating: blankLine, count: trailing)
            coverageRows = Array(repeating: blankCoverage, count: leading) + coverageRows + Array(repeating: blankCoverage, count: trailing)
        }
    } else if extra < 0 {
        paddedLines = Array(paddedLines.prefix(height))
        coverageRows = Array(coverageRows.prefix(height))
    }

    if paddedLines.isEmpty {
        paddedLines = Array(repeating: blankLine, count: height)
        coverageRows = Array(repeating: blankCoverage, count: height)
    }

    return PaddedLayer(lines: paddedLines, coverage: coverageRows)
}

private func padLine(line: String, width: Int, horizontal: ZStack.Alignment.Horizontal) -> (String, [Bool]) {
    let visible = HStack.visibleWidth(of: line)
    if visible >= width {
        let coverage = Array(repeating: true, count: width)
        return (line, coverage)
    }
    let padding = width - visible
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
    let coverage = Array(repeating: false, count: spaces.leading) + Array(repeating: true, count: visible) + Array(repeating: false, count: spaces.trailing)
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

private func mergeLine(base: String, overlay: String, coverage: [Bool]) -> String {
    let (baseColumns, baseTrailing) = columns(from: base)
    let (overlayColumns, overlayTrailing) = columns(from: overlay)
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
    return result
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
