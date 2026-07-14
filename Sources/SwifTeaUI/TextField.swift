public struct TextField: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("TextField has no body")
    }

    private let placeholder: String
    private let text: Binding<String>
    private let focus: Binding<Bool>?
    private let cursorSymbol: String
    private let focusStyle: FocusStyle
    private let blinkingCursor: Bool
    private let cursorPosition: Binding<Int>?

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        focus: Binding<Bool>? = nil,
        cursor: String = " ",
        focusStyle: FocusStyle = .default,
        blinkingCursor: Bool = false,
        cursorPosition: Binding<Int>? = nil
    ) {
        self.placeholder = placeholder
        self.text = text
        self.focus = focus
        self.cursorSymbol = cursor
        self.focusStyle = focusStyle
        self.blinkingCursor = blinkingCursor
        self.cursorPosition = cursorPosition
    }

    public func render() -> String {
        let value = text.wrappedValue
        let isPlaceholder = value.isEmpty
        let body = isPlaceholder ? placeholder : value
        let isFocused = focus?.wrappedValue ?? true
        guard isFocused else { return body }

        var cursorIndex = cursorPosition?.wrappedValue ?? value.count
        cursorIndex = max(0, min(cursorIndex, body.count))
        if let cursorPosition, cursorPosition.wrappedValue != cursorIndex {
            cursorPosition.wrappedValue = cursorIndex
        }

        let sentinel = "\u{0000}"
        var renderText = body
        var underlyingChar: Character? = nil
        if cursorIndex < renderText.count {
            let idx = renderText.index(renderText.startIndex, offsetBy: cursorIndex)
            underlyingChar = renderText[idx]
            renderText.remove(at: idx)
        }
        let insertionIndex = min(cursorIndex, renderText.count)
        let index = renderText.index(renderText.startIndex, offsetBy: insertionIndex)
        renderText.insert(contentsOf: sentinel, at: index)

        let cursorSeed = underlyingChar.map(String.init) ?? cursorSymbol
        let cursorDisplay =
            blinkingCursor
            ? CursorBlinker.shared.cursor(for: cursorSeed)
            : cursorSeed

        let isHiddenCursor = cursorDisplay.allSatisfy { $0 == " " }
        let overlay: String
        if isHiddenCursor {
            if let ch = underlyingChar {
                let str = String(ch)
                if str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    overlay = "\u{001B}[7m" + str + ANSIColor.reset.rawValue
                } else {
                    overlay = str
                }
            } else {
                overlay = "\u{001B}[7m \u{001B}[0m"
            }
        } else {
            overlay = "\u{001B}[7m" + cursorDisplay + ANSIColor.reset.rawValue
        }
        if let range = renderText.range(of: sentinel) {
            renderText.replaceSubrange(range, with: overlay)
        }

        return focusStyle.apply(to: renderText)
    }

    public func focusRingStyle(_ style: FocusStyle) -> TextField {
        TextField(
            placeholder,
            text: text,
            focus: focus,
            cursor: cursorSymbol,
            focusStyle: style,
            blinkingCursor: blinkingCursor,
            cursorPosition: cursorPosition
        )
    }

    @available(*, deprecated, message: "Use focusRingStyle(_:) for clarity.")
    public func focusStyle(_ style: FocusStyle) -> TextField {
        focusRingStyle(style)
    }

    public func blinkingCursor(_ enabled: Bool = true) -> TextField {
        TextField(
            placeholder,
            text: text,
            focus: focus,
            cursor: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: enabled,
            cursorPosition: cursorPosition
        )
    }

    public func focused(_ binding: Binding<Bool>) -> TextField {
        TextField(
            placeholder,
            text: text,
            focus: binding,
            cursor: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: blinkingCursor,
            cursorPosition: cursorPosition
        )
    }

    public func cursorPosition(_ binding: Binding<Int>) -> TextField {
        TextField(
            placeholder,
            text: text,
            focus: focus,
            cursor: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: blinkingCursor,
            cursorPosition: binding
        )
    }
}

public enum TextFieldEvent: Equatable, Sendable {
    case insert(Character)
    case backspace
    case submit
    case moveCursor(Int)
}

public func textFieldEvent(from key: KeyEvent) -> TextFieldEvent? {
    switch key {
    case .char(let character):
        return .insert(character)
    case .backspace:
        return .backspace
    case .enter:
        return .submit
    case .leftArrow:
        return .moveCursor(-1)
    case .rightArrow:
        return .moveCursor(1)
    default:
        return nil
    }
}

extension Binding where Value == String {
    public func apply(_ event: TextFieldEvent) {
        update { value in
            switch event {
            case .insert(let character):
                value.append(character)
            case .backspace:
                if !value.isEmpty {
                    value.removeLast()
                }
            case .submit:
                break
            case .moveCursor:
                break
            }
        }
    }
}
