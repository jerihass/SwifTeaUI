import SwifTeaCore

public struct TextField: TUIView {
    private let placeholder: String
    private let text: Binding<String>
    private let isFocused: Bool
    private let cursorSymbol: String

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        isFocused: Bool = true,
        cursor: String = "|"
    ) {
        self.placeholder = placeholder
        self.text = text
        self.isFocused = isFocused
        self.cursorSymbol = cursor
    }

    public func render() -> String {
        let value = text.wrappedValue
        let body = value.isEmpty ? placeholder : value
        guard isFocused else { return body }
        return body + cursorSymbol
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
