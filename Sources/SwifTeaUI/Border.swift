
public struct Border<Content: TUIView>: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Border has no body")
    }

    private let content: Content
    private let padding: Int
    private let borderColor: ANSIColor?
    private let borderBold: Bool
    private let backgroundColor: ANSIColor?

    public init(_ content: Content) {
        self.init(padding: 1, color: nil, bold: false, background: nil, content)
    }

    public init(padding: Int, _ content: Content) {
        self.init(padding: padding, color: nil, bold: false, background: nil, content)
    }

    public init(
        padding: Int,
        color: ANSIColor? = nil,
        bold: Bool = false,
        background: ANSIColor? = nil,
        _ content: Content
    ) {
        precondition(padding >= 0, "Border padding must be non-negative.")
        self.content = content
        self.padding = padding
        self.borderColor = color
        self.borderBold = bold
        self.backgroundColor = background
    }

    public func render() -> String {
        let inner = content.render()
        let lines = inner.splitLinesPreservingEmpty()
        let width = lines.map { Self.visibleWidth(of: $0) }.max() ?? 0
        let paddingString = String(repeating: " ", count: padding)
        let horizontal = String(repeating: "─", count: width + padding * 2)
        let top = decorateHorizontal("┌" + horizontal + "┐")
        let bottom = decorateHorizontal("└" + horizontal + "┘")

        let leftBorder = decorateVertical("│")
        let rightBorder = decorateVertical("│")

        let body = lines.map { line -> String in
            let padded = Self.pad(line, toVisibleWidth: width)
            let interior = paddingString + padded + paddingString
            let filledInterior = applyInteriorBackground(interior)
            return leftBorder + filledInterior + rightBorder
        }

        return ([top] + body + [bottom]).joined(separator: "\n")
    }

    private func decorateHorizontal(_ line: String) -> String {
        guard let style = borderStyle else { return line }
        return style.prefix + line + style.suffix
    }

    private func decorateVertical(_ character: String) -> String {
        guard let style = borderStyle else { return character }
        return style.prefix + character + style.suffix
    }

    private var borderStyle: (prefix: String, suffix: String)? {
        guard borderColor != nil || borderBold || backgroundColor != nil else { return nil }
        let prefix =
            (backgroundColor?.backgroundCode ?? "")
            + (borderColor?.rawValue ?? "")
            + (borderBold ? "\u{001B}[1m" : "")
        return (prefix, ANSIColor.reset.rawValue)
    }

    private static func visibleWidth(of string: String) -> Int {
        var width = 0
        var iterator = string.makeIterator()
        var inEscape = false

        while let character = iterator.next() {
            if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
            } else if character == "\u{001B}" {
                inEscape = true
            } else {
                width += 1
            }
        }

        return width
    }

    private static func pad(_ line: String, toVisibleWidth width: Int) -> String {
        let current = visibleWidth(of: line)
        guard current < width else { return line }
        let padding = width - current
        return line + String(repeating: " ", count: padding)
    }

    private func applyInteriorBackground(_ string: String) -> String {
        guard let backgroundColor else { return string }
        let prefix = backgroundColor.backgroundCode
        let reset = ANSIColor.reset.rawValue
        guard !prefix.isEmpty, prefix != reset else { return string }

        var result = String()
        result.reserveCapacity(string.count + prefix.count * 2)
        result.append(prefix)

        var inEscape = false
        var sequence = ""

        for character in string {
            result.append(character)
            if inEscape {
                sequence.append(character)
                if character.isANSISequenceTerminator {
                    inEscape = false
                    switch classifyInteriorSequence(sequence) {
                    case .reset:
                        result.append(prefix)
                    case .set, .other:
                        break
                    }
                    sequence.removeAll(keepingCapacity: true)
                }
            } else if character == "\u{001B}" {
                inEscape = true
                sequence = String(character)
            }
        }

        result.append(reset)
        return result
    }

    private enum InteriorSequenceType {
        case set
        case reset
        case other
    }

    private func classifyInteriorSequence(_ sequence: String) -> InteriorSequenceType {
        if sequence == ANSIColor.reset.rawValue { return .reset }
        guard sequence.hasPrefix("\u{001B}["),
              let last = sequence.last,
              last == "m" else { return .other }
        let body = sequence.dropFirst(2).dropLast()
        guard let first = body.split(separator: ";").first else { return .other }

        if first == "0" || first == "49" { return .reset }
        if first == "48" { return .set }

        if let value = Int(first) {
            if (40...47).contains(value) || (100...107).contains(value) {
                return .set
            }
        }

        return .other
    }
}

public struct FocusRingBorder<Content: TUIView>: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("FocusRingBorder has no body")
    }

    private let content: Content
    private let padding: Int
    private let isFocused: Bool
    private let style: FocusStyle

    public init(
        padding: Int = 1,
        isFocused: Bool,
        style: FocusStyle = .default,
        _ content: Content
    ) {
        self.padding = padding
        self.isFocused = isFocused
        self.style = style
        self.content = content
    }

    public func render() -> String {
        let borderColor: ANSIColor? = isFocused ? style.color : nil
        return Border(
            padding: padding,
            color: borderColor,
            bold: isFocused ? style.bold : false,
            background: nil,
            content
        ).render()
    }
}

public extension TUIView {
    func border(
        padding: Int = 1,
        color: ANSIColor? = nil,
        bold: Bool = false,
        background: ANSIColor? = nil
    ) -> some TUIView {
        Border(padding: padding, color: color, bold: bold, background: background, self)
    }

    func focusRing(
        padding: Int = 1,
        isFocused: Bool,
        style: FocusStyle = .default
    ) -> some TUIView {
        FocusRingBorder(padding: padding, isFocused: isFocused, style: style, self)
    }
}
