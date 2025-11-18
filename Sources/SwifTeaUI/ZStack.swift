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

        var canvas = paddedLayers.first ?? Array(repeating: String(repeating: " ", count: maxWidth), count: maxHeight)
        for layer in paddedLayers.dropFirst() {
            for index in layer.indices {
                canvas[index] = mergeLine(base: canvas[index], overlay: layer[index])
            }
        }

        return canvas.joined(separator: "\n")
    }
}

private func pad(lines: [String], width: Int, height: Int, alignment: ZStack.Alignment) -> [String] {
    var padded = lines.map { pad(line: $0, width: width, horizontal: alignment.horizontal) }
    let blankLine = String(repeating: " ", count: width)
    let extra = height - padded.count
    if extra > 0 {
        switch alignment.vertical {
        case .top:
            padded.append(contentsOf: Array(repeating: blankLine, count: extra))
        case .bottom:
            padded = Array(repeating: blankLine, count: extra) + padded
        case .center:
            let leading = extra / 2
            let trailing = extra - leading
            padded = Array(repeating: blankLine, count: leading) + padded + Array(repeating: blankLine, count: trailing)
        }
    } else if extra < 0 {
        padded = Array(padded.prefix(height))
    }

    if padded.isEmpty {
        padded = Array(repeating: blankLine, count: height)
    }

    return padded
}

private func pad(line: String, width: Int, horizontal: ZStack.Alignment.Horizontal) -> String {
    let visible = HStack.visibleWidth(of: line)
    guard visible < width else { return line }
    let padding = width - visible
    switch horizontal {
    case .leading:
        return line + String(repeating: " ", count: padding)
    case .trailing:
        return String(repeating: " ", count: padding) + line
    case .center:
        let leading = padding / 2
        let trailing = padding - leading
        return String(repeating: " ", count: leading) + line + String(repeating: " ", count: trailing)
    }
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

private func mergeLine(base: String, overlay: String) -> String {
    let (baseColumns, baseTrailing) = columns(from: base)
    let (overlayColumns, overlayTrailing) = columns(from: overlay)
    let width = max(baseColumns.count, overlayColumns.count)
    var result = ""

    for index in 0..<width {
        let baseColumn = index < baseColumns.count ? baseColumns[index] : ANSIColumn(prefix: "", char: " ")
        let overlayColumn = index < overlayColumns.count ? overlayColumns[index] : ANSIColumn(prefix: "", char: " ")
        let useOverlay = !(overlayColumn.char == " " && overlayColumn.prefix.isEmpty)
        if useOverlay {
            result += overlayColumn.prefix
            result.append(overlayColumn.char)
        } else {
            result += baseColumn.prefix
            result.append(baseColumn.char)
        }
    }

    result += overlayTrailing
    result += baseTrailing
    return result
}
