
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

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        focus: Binding<Bool>? = nil,
        cursor: String = "|",
        focusStyle: FocusStyle = .default,
        blinkingCursor: Bool = false
    ) {
        self.placeholder = placeholder
        self.text = text
        self.focus = focus
        self.cursorSymbol = cursor
        self.focusStyle = focusStyle
        self.blinkingCursor = blinkingCursor
    }

    public func render() -> String {
        let value = text.wrappedValue
        let body = value.isEmpty ? placeholder : value
        let isFocused = focus?.wrappedValue ?? true
        guard isFocused else { return body }
        let cursor = blinkingCursor
            ? CursorBlinker.shared.cursor(for: cursorSymbol)
            : cursorSymbol
        return focusStyle.apply(to: body + cursor)
    }

    public func focusRingStyle(_ style: FocusStyle) -> TextField {
        TextField(
            placeholder,
            text: text,
            focus: focus,
            cursor: cursorSymbol,
            focusStyle: style,
            blinkingCursor: blinkingCursor
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
            blinkingCursor: enabled
        )
    }

    public func focused(_ binding: Binding<Bool>) -> TextField {
        TextField(
            placeholder,
            text: text,
            focus: binding,
            cursor: cursorSymbol,
            focusStyle: focusStyle,
            blinkingCursor: blinkingCursor
        )
    }
}

public enum TextFieldEvent: Equatable {
    case insert(Character)
    case backspace
    case submit
}

public func textFieldEvent(from key: KeyEvent) -> TextFieldEvent? {
    switch key {
    case .char(let character):
        return .insert(character)
    case .backspace:
        return .backspace
    case .enter:
        return .submit
    default:
        return nil
    }
}

public extension Binding where Value == String {
    func apply(_ event: TextFieldEvent) {
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
            }
        }
    }
}
