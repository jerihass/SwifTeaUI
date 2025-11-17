import Foundation

public enum KeyEvent: Equatable {
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
