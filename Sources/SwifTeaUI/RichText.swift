public struct TextStyle: Equatable, Sendable {
    public var foregroundColor: ANSIColor?
    public var backgroundColor: ANSIColor?
    public var isBold: Bool
    public var isItalic: Bool
    public var isUnderlined: Bool

    public init(
        foregroundColor: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
    }

    public static let plain = TextStyle()

    var prefix: String {
        var result = ""
        if let foregroundColor { result += foregroundColor.rawValue }
        if let backgroundColor { result += backgroundColor.backgroundCode }
        if isBold { result += "\u{001B}[1m" }
        if isItalic { result += "\u{001B}[3m" }
        if isUnderlined { result += "\u{001B}[4m" }
        return result
    }
}

public struct TextSpan: Equatable, Sendable {
    public let content: String
    public let style: TextStyle

    public init(_ content: String, style: TextStyle = .plain) {
        self.content = content
        self.style = style
    }

    public func foregroundColor(_ color: ANSIColor?) -> TextSpan {
        withStyle { $0.foregroundColor = color }
    }

    public func backgroundColor(_ color: ANSIColor?) -> TextSpan {
        withStyle { $0.backgroundColor = color }
    }

    public func bold(_ enabled: Bool = true) -> TextSpan {
        withStyle { $0.isBold = enabled }
    }

    public func italic(_ enabled: Bool = true) -> TextSpan {
        withStyle { $0.isItalic = enabled }
    }

    public func underline(_ enabled: Bool = true) -> TextSpan {
        withStyle { $0.isUnderlined = enabled }
    }

    private func withStyle(_ update: (inout TextStyle) -> Void) -> TextSpan {
        var style = style
        update(&style)
        return TextSpan(content, style: style)
    }
}

@resultBuilder
public enum TextSpanBuilder {
    public static func buildBlock(_ components: [TextSpan]...) -> [TextSpan] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: TextSpan) -> [TextSpan] { [expression] }
    public static func buildExpression(_ expression: [TextSpan]) -> [TextSpan] { expression }
    public static func buildOptional(_ component: [TextSpan]?) -> [TextSpan] { component ?? [] }
    public static func buildEither(first component: [TextSpan]) -> [TextSpan] { component }
    public static func buildEither(second component: [TextSpan]) -> [TextSpan] { component }
    public static func buildArray(_ components: [[TextSpan]]) -> [TextSpan] {
        components.flatMap { $0 }
    }
}

public struct InlineGroup: Equatable, Sendable {
    let spans: [TextSpan]

    public init(@TextSpanBuilder _ content: () -> [TextSpan]) {
        spans = content()
    }
}

public enum RichTextElement: Equatable, Sendable {
    case span(TextSpan)
    case group(InlineGroup)
}

@resultBuilder
public enum RichTextBuilder {
    public static func buildBlock(_ components: [RichTextElement]...) -> [RichTextElement] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: TextSpan) -> [RichTextElement] {
        [.span(expression)]
    }

    public static func buildExpression(_ expression: InlineGroup) -> [RichTextElement] {
        [.group(expression)]
    }

    public static func buildExpression(_ expression: [RichTextElement]) -> [RichTextElement] {
        expression
    }

    public static func buildOptional(_ component: [RichTextElement]?) -> [RichTextElement] {
        component ?? []
    }

    public static func buildEither(first component: [RichTextElement]) -> [RichTextElement] {
        component
    }
    public static func buildEither(second component: [RichTextElement]) -> [RichTextElement] {
        component
    }
    public static func buildArray(_ components: [[RichTextElement]]) -> [RichTextElement] {
        components.flatMap { $0 }
    }
}

public struct RichText: TUIView {
    public typealias Body = Never

    private let width: Int?
    private let elements: [RichTextElement]

    public init(width: Int? = nil, @RichTextBuilder _ content: () -> [RichTextElement]) {
        self.width = width.map { max(1, $0) }
        self.elements = content()
    }

    public var body: Never {
        fatalError("RichText has no body")
    }

    public func render() -> String {
        render(in: RenderEnvironment.current)
    }

    public func render(in context: RenderContext) -> String {
        let resolvedWidth = width ?? context.proposedSize.width
        return render(lines: layout(width: resolvedWidth))
    }

    private struct Cell {
        let character: Character
        let width: Int
        let style: TextStyle
    }

    private enum Token {
        case chunk([Cell])
        case whitespace([Cell])
        case newline
    }

    private func layout(width: Int?) -> [[Cell]] {
        let tokens = tokens()
        guard let width else { return unwrappedLines(tokens) }

        let limit = max(1, width)
        var lines: [[Cell]] = []
        var line: [Cell] = []
        var lineWidth = 0
        var pendingWhitespace: [Cell] = []

        func appendLine() {
            lines.append(line)
            line = []
            lineWidth = 0
            pendingWhitespace = []
        }

        func appendChunk(_ cells: [Cell]) {
            var segment: [Cell] = []
            var segmentWidth = 0
            for cell in cells {
                if cell.width > limit {
                    if !segment.isEmpty {
                        line += segment
                        lineWidth += segmentWidth
                        appendLine()
                        segment = []
                        segmentWidth = 0
                    }
                    line.append(Cell(character: "�", width: 1, style: cell.style))
                    lineWidth += 1
                    appendLine()
                } else if segmentWidth + cell.width > limit {
                    line += segment
                    lineWidth += segmentWidth
                    appendLine()
                    segment = [cell]
                    segmentWidth = cell.width
                } else {
                    segment.append(cell)
                    segmentWidth += cell.width
                }
            }
            line += segment
            lineWidth += segmentWidth
        }

        for token in tokens {
            switch token {
            case .newline:
                if !pendingWhitespace.isEmpty {
                    let available = max(0, limit - lineWidth)
                    line += prefix(pendingWhitespace, fitting: available)
                }
                appendLine()
            case .whitespace(let cells):
                pendingWhitespace += cells
            case .chunk(let cells):
                let whitespaceWidth = pendingWhitespace.reduce(0) { $0 + $1.width }
                let chunkWidth = cells.reduce(0) { $0 + $1.width }
                if !line.isEmpty, lineWidth + whitespaceWidth + chunkWidth > limit {
                    appendLine()
                } else if !pendingWhitespace.isEmpty {
                    let available = max(0, limit - lineWidth)
                    let whitespace = prefix(pendingWhitespace, fitting: available)
                    line += whitespace
                    lineWidth += whitespace.reduce(0) { $0 + $1.width }
                }
                pendingWhitespace = []

                if lineWidth + chunkWidth <= limit {
                    line += cells
                    lineWidth += chunkWidth
                } else {
                    appendChunk(cells)
                }
            }
        }

        if !pendingWhitespace.isEmpty {
            let available = max(0, limit - lineWidth)
            line += prefix(pendingWhitespace, fitting: available)
        }
        if !line.isEmpty || lines.isEmpty { lines.append(line) }
        return lines
    }

    private func unwrappedLines(_ tokens: [Token]) -> [[Cell]] {
        var lines: [[Cell]] = [[]]
        for token in tokens {
            switch token {
            case .newline:
                lines.append([])
            case .chunk(let cells), .whitespace(let cells):
                lines[lines.count - 1] += cells
            }
        }
        return lines
    }

    private func tokens() -> [Token] {
        var result: [Token] = []
        var word: [Cell] = []
        var whitespace: [Cell] = []

        func flushWord() {
            if !word.isEmpty {
                result.append(.chunk(word))
                word = []
            }
        }

        func flushWhitespace() {
            if !whitespace.isEmpty {
                result.append(.whitespace(whitespace))
                whitespace = []
            }
        }

        func append(span: TextSpan) {
            for character in span.content {
                if character == "\n" {
                    flushWord()
                    flushWhitespace()
                    result.append(.newline)
                } else if character.isWhitespace {
                    flushWord()
                    whitespace.append(cell(character, style: span.style))
                } else {
                    flushWhitespace()
                    word.append(cell(character, style: span.style))
                }
            }
        }

        for element in elements {
            switch element {
            case .span(let span):
                append(span: span)
            case .group(let group):
                flushWord()
                flushWhitespace()
                var cells: [Cell] = []
                for span in group.spans {
                    for character in span.content {
                        if character == "\n" {
                            if !cells.isEmpty { result.append(.chunk(cells)) }
                            result.append(.newline)
                            cells = []
                        } else {
                            cells.append(cell(character, style: span.style))
                        }
                    }
                }
                if !cells.isEmpty { result.append(.chunk(cells)) }
            }
        }
        flushWord()
        flushWhitespace()
        return result
    }

    private func cell(_ character: Character, style: TextStyle) -> Cell {
        Cell(character: character, width: TerminalText.cellWidth(of: character), style: style)
    }

    private func prefix(_ cells: [Cell], fitting width: Int) -> [Cell] {
        var result: [Cell] = []
        var used = 0
        for cell in cells where used + cell.width <= width {
            result.append(cell)
            used += cell.width
        }
        return result
    }

    private func render(lines: [[Cell]]) -> String {
        lines.map(render(line:)).joined(separator: "\n")
    }

    private func render(line: [Cell]) -> String {
        var result = ""
        var activeStyle = TextStyle.plain

        for cell in line {
            if cell.style != activeStyle {
                if activeStyle != .plain { result += ANSIColor.reset.rawValue }
                result += cell.style.prefix
                activeStyle = cell.style
            }
            result.append(cell.character)
        }
        if activeStyle != .plain { result += ANSIColor.reset.rawValue }
        return result
    }
}
