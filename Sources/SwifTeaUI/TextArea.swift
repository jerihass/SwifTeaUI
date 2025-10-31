import SwifTeaCore

public struct TextArea: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("TextArea has no body")
    }

    private let placeholder: String
    private let text: Binding<String>
    private let focus: Binding<Bool>?
    private let cursorSymbol: String
    private let wrapWidth: Int

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        focus: Binding<Bool>? = nil,
        width: Int = 60,
        cursor: String = "|"
    ) {
        self.placeholder = placeholder
        self.text = text
        self.focus = focus
        self.cursorSymbol = cursor
        self.wrapWidth = max(1, width)
    }

    public func render() -> String {
        let value = text.wrappedValue
        let isFocused = focus?.wrappedValue ?? true
        let display = value.isEmpty ? placeholder : value
        var lines = wrap(display, width: wrapWidth)

        if isFocused {
            if lines.isEmpty {
                lines = [cursorSymbol]
            } else {
                lines[lines.count - 1] += cursorSymbol
            }
        }

        return lines.joined(separator: "\n")
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
}
