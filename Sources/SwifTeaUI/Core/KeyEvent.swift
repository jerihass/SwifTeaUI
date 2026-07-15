import Foundation

public enum KeyEvent: Equatable, Sendable {
    case char(Character)
    case enter
    case backspace
    case tab
    case backTab
    case escape
    case ctrlC
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
}

/// One normalized input unit delivered by the terminal runtime.
public enum TerminalInputEvent: Equatable, Sendable {
    case key(KeyEvent)
    case paste(String)
}

/// Runtime-owned terminal input features and their memory limits.
public struct TerminalInputOptions: Equatable, Sendable {
    public var bracketedPaste: Bool
    public var maximumPasteBytes: Int

    public init(
        bracketedPaste: Bool = false,
        maximumPasteBytes: Int = 1_048_576
    ) {
        self.bracketedPaste = bracketedPaste
        self.maximumPasteBytes = max(0, maximumPasteBytes)
    }
}
