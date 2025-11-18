
public struct TextEditor: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("TextEditor has no body")
    }

    private let placeholder: String
    private let text: Binding<String>
    private let focus: Binding<Bool>?
    private let cursorSymbol: String
    private let cursorPositionBinding: Binding<Int>?
    private let cursorLineBinding: Binding<Int>?
    private let wrapWidth: Int
    private let focusStyle: FocusStyle
    private let blinkingCursor: Bool

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        focus: Binding<Bool>? = nil,
        width: Int = 60,
        cursorSymbol: String = "█",
        focusStyle: FocusStyle = .default,
        blinkingCursor: Bool = false,
        cursorPosition: Binding<Int>? = nil,
        cursorLine: Binding<Int>? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.focus = focus
        self.cursorSymbol = cursorSymbol
        self.cursorPositionBinding = cursorPosition
        self.cursorLineBinding = cursorLine
        self.wrapWidth = max(1, width)
        self.focusStyle = focusStyle
        self.blinkingCursor = blinkingCursor
    }

    public func render() -> String {
        let value = text.wrappedValue
        let isFocused = focus?.wrappedValue ?? true
        let sentinel = "\u{0000}"

        var cursorIndex = cursorPositionBinding?.wrappedValue ?? value.count
        cursorIndex = max(0, min(cursorIndex, value.count))
        if let cursorPositionBinding, cursorPositionBinding.wrappedValue != cursorIndex {
            cursorPositionBinding.wrappedValue = cursorIndex
        }

        var renderText = value.isEmpty ? placeholder : value
        let insertionIndex = renderText == value
            ? min(cursorIndex, renderText.count)
            : min(cursorIndex, renderText.count)
        let index = renderText.index(renderText.startIndex, offsetBy: insertionIndex)
        renderText.insert(contentsOf: sentinel, at: index)

        var lines = wrap(renderText, width: wrapWidth)

        let targetWidth = wrapWidth + 1
        let cursorDisplay = blinkingCursor
            ? CursorBlinker.shared.cursor(for: cursorSymbol)
            : cursorSymbol

        var detectedCursorLine: Int?

        for lineIndex in lines.indices {
            if let range = lines[lineIndex].range(of: sentinel) {
                detectedCursorLine = lineIndex
                if isFocused {
                    lines[lineIndex].replaceSubrange(range, with: cursorDisplay)
                    lines[lineIndex] = focusStyle.apply(to: lines[lineIndex])
                } else {
                    lines[lineIndex].removeSubrange(range)
                }
                break
            }
        }

        if let cursorLineBinding {
            cursorLineBinding.wrappedValue = detectedCursorLine ?? 0
        }

        let paddedLines = lines.map { line -> String in
            let visible = HStack.visibleWidth(of: line)
            if visible >= targetWidth { return line }
            return line + String(repeating: " ", count: targetWidth - visible)
        }

        return paddedLines.joined(separator: "\n")
    }

    private func wrap(_ text: String, width: Int) -> [String] {
        guard !text.isEmpty else { return [""] }

        var result: [String] = []
        var currentSegment = ""

        for character in text {
            if character == "\n" {
                result.append(contentsOf: wrapSegment(currentSegment, width: width))
                result.append("")
                currentSegment.removeAll(keepingCapacity: true)
            } else {
                currentSegment.append(character)
            }
        }

        result.append(contentsOf: wrapSegment(currentSegment, width: width))

        // Remove trailing empty line introduced by terminal newline handling.
        if let last = result.last, last.isEmpty {
            // Only trim if the original text did not explicitly ask for an empty trailing line.
            if !text.hasSuffix("\n") {
                result.removeLast()
            }
        }

        return result.isEmpty ? [""] : result
    }

    private func wrapSegment(_ segment: String, width: Int) -> [String] {
        guard !segment.isEmpty else { return [""] }

        var lines: [String] = []
        var index = segment.startIndex

        while index < segment.endIndex {
            let upperBound = segment.index(index, offsetBy: width, limitedBy: segment.endIndex) ?? segment.endIndex

            if upperBound == segment.endIndex {
                lines.append(String(segment[index..<upperBound]))
                break
            }

            var breakIndex = upperBound
            var foundBreak = false

            while breakIndex > index {
                let prev = segment.index(before: breakIndex)
                if segment[prev].isWhitespace {
                    foundBreak = true
                    breakIndex = prev
                    break
                }
                breakIndex = prev
            }

            if foundBreak {
                lines.append(String(segment[index..<breakIndex]))
                index = segment.index(after: breakIndex)
            } else {
                lines.append(String(segment[index..<upperBound]))
                index = upperBound
            }
        }

        return lines.isEmpty ? [""] : lines
    }

    public func focusRingStyle(_ style: FocusStyle) -> TextEditor {
        TextEditor(
            placeholder,
            text: text,
            focus: focus,
            width: wrapWidth,
            cursorSymbol: cursorSymbol,
            focusStyle: style,
            blinkingCursor: blinkingCursor,
            cursorPosition: cursorPositionBinding,
            cursorLine: cursorLineBinding
        )
    }

    @available(*, deprecated, message: "Use focusRingStyle(_:) for clarity.")
    public func focusStyle(_ style: FocusStyle) -> TextEditor {
        focusRingStyle(style)
    }

    public func blinkingCursor(_ enabled: Bool = true) -> TextEditor {
        TextEditor(
            placeholder,
            text: text,
            focus: focus,
            width: wrapWidth,
            cursorSymbol: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: enabled,
            cursorPosition: cursorPositionBinding,
            cursorLine: cursorLineBinding
        )
    }

    public func focused(_ binding: Binding<Bool>) -> TextEditor {
        TextEditor(
            placeholder,
            text: text,
            focus: binding,
            width: wrapWidth,
            cursorSymbol: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: blinkingCursor,
            cursorPosition: cursorPositionBinding,
            cursorLine: cursorLineBinding
        )
    }

    public func cursorPosition(_ binding: Binding<Int>) -> TextEditor {
        TextEditor(
            placeholder,
            text: text,
            focus: focus,
            width: wrapWidth,
            cursorSymbol: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: blinkingCursor,
            cursorPosition: binding,
            cursorLine: cursorLineBinding
        )
    }

    public func cursorLine(_ binding: Binding<Int>) -> TextEditor {
        TextEditor(
            placeholder,
            text: text,
            focus: focus,
            width: wrapWidth,
            cursorSymbol: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: blinkingCursor,
            cursorPosition: cursorPositionBinding,
            cursorLine: binding
        )
    }
}

public typealias TextArea = TextEditor
