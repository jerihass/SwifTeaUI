public enum ANSI {
    public static let esc = "\u{001B}"
    public static let clear = "\(esc)[2J"
    public static let home = "\(esc)[H"
    public static func color(_ code: Int) -> String { "\(esc)[\(code)m" }
    public static let reset = color(0)
}

public struct ANSIColor: Equatable, Sendable {
    private enum Storage: Equatable, Sendable {
        case reset
        case basic(Basic)
        case indexed(UInt8)
        case trueColor(red: UInt8, green: UInt8, blue: UInt8)
    }

    public enum Basic: Int, Sendable {
        case black = 30
        case red = 31
        case green = 32
        case yellow = 33
        case blue = 34
        case magenta = 35
        case cyan = 36
        case white = 37
        case brightBlack = 90
        case brightRed = 91
        case brightGreen = 92
        case brightYellow = 93
        case brightBlue = 94
        case brightMagenta = 95
        case brightCyan = 96
        case brightWhite = 97

        init?(indexedCode: UInt8) {
            switch indexedCode {
            case 0: self = .black
            case 1: self = .red
            case 2: self = .green
            case 3: self = .yellow
            case 4: self = .blue
            case 5: self = .magenta
            case 6: self = .cyan
            case 7: self = .white
            case 8: self = .brightBlack
            case 9: self = .brightRed
            case 10: self = .brightGreen
            case 11: self = .brightYellow
            case 12: self = .brightBlue
            case 13: self = .brightMagenta
            case 14: self = .brightCyan
            case 15: self = .brightWhite
            default: return nil
            }
        }

        func code(isBackground: Bool) -> Int {
            isBackground ? rawValue + 10 : rawValue
        }

        var rgbComponents: (Int, Int, Int) {
            switch self {
            case .black:
                return (0, 0, 0)
            case .red:
                return (205, 49, 49)
            case .green:
                return (13, 188, 121)
            case .yellow:
                return (229, 229, 16)
            case .blue:
                return (36, 114, 200)
            case .magenta:
                return (188, 63, 188)
            case .cyan:
                return (17, 168, 205)
            case .white:
                return (229, 229, 229)
            case .brightBlack:
                return (102, 102, 102)
            case .brightRed:
                return (241, 76, 76)
            case .brightGreen:
                return (35, 209, 139)
            case .brightYellow:
                return (245, 245, 67)
            case .brightBlue:
                return (59, 142, 234)
            case .brightMagenta:
                return (214, 112, 214)
            case .brightCyan:
                return (41, 184, 219)
            case .brightWhite:
                return (255, 255, 255)
            }
        }
    }

    private let storage: Storage

    private init(_ storage: Storage) {
        self.storage = storage
    }

    public static let reset = ANSIColor(.reset)
    public static let black = ANSIColor(.basic(.black))
    public static let red = ANSIColor(.basic(.red))
    public static let green = ANSIColor(.basic(.green))
    public static let yellow = ANSIColor(.basic(.yellow))
    public static let blue = ANSIColor(.basic(.blue))
    public static let magenta = ANSIColor(.basic(.magenta))
    public static let cyan = ANSIColor(.basic(.cyan))
    public static let white = ANSIColor(.basic(.white))
    public static let brightBlack = ANSIColor(.basic(.brightBlack))
    public static let brightRed = ANSIColor(.basic(.brightRed))
    public static let brightGreen = ANSIColor(.basic(.brightGreen))
    public static let brightYellow = ANSIColor(.basic(.brightYellow))
    public static let brightBlue = ANSIColor(.basic(.brightBlue))
    public static let brightMagenta = ANSIColor(.basic(.brightMagenta))
    public static let brightCyan = ANSIColor(.basic(.brightCyan))
    public static let brightWhite = ANSIColor(.basic(.brightWhite))

    public static func indexed(_ code: UInt8) -> ANSIColor {
        ANSIColor(.indexed(code))
    }

    public static func trueColor(red: Int, green: Int, blue: Int) -> ANSIColor {
        ANSIColor(
            .trueColor(
                red: UInt8(clamping: red),
                green: UInt8(clamping: green),
                blue: UInt8(clamping: blue)
            )
        )
    }

    public var rawValue: String {
        escapeSequence(isBackground: false)
    }

    public var backgroundCode: String {
        escapeSequence(isBackground: true)
    }

    public var rgbComponents: (Int, Int, Int) {
        switch storage {
        case .reset:
            return (0, 0, 0)
        case .basic(let basic):
            return basic.rgbComponents
        case .indexed(let code):
            return ANSIColor.rgbComponents(forIndexedColor: code)
        case .trueColor(let red, let green, let blue):
            return (Int(red), Int(green), Int(blue))
        }
    }

    private func escapeSequence(isBackground: Bool) -> String {
        switch storage {
        case .reset:
            return ANSI.reset
        case .basic(let basic):
            return ANSI.color(basic.code(isBackground: isBackground))
        case .indexed(let code):
            let prefix = isBackground ? "48;5;\(code)" : "38;5;\(code)"
            return "\(ANSI.esc)[\(prefix)m"
        case .trueColor(let red, let green, let blue):
            let prefix = isBackground ? "48;2;\(red);\(green);\(blue)" : "38;2;\(red);\(green);\(blue)"
            return "\(ANSI.esc)[\(prefix)m"
        }
    }

    private static func rgbComponents(forIndexedColor code: UInt8) -> (Int, Int, Int) {
        if let basic = Basic(indexedCode: code) {
            return basic.rgbComponents
        }

        if code >= 232 {
            let level = Int(code) - 232
            let value = 8 + level * 10
            return (value, value, value)
        }

        let cubeIndex = Int(code) - 16
        let r = cubeIndex / 36
        let g = (cubeIndex % 36) / 6
        let b = cubeIndex % 6
        let steps = [0, 95, 135, 175, 215, 255]

        return (steps[r], steps[g], steps[b])
    }
}

extension Character {
    var isANSISequenceTerminator: Bool {
        switch self {
        case "a"..."z", "A"..."Z":
            return true
        default:
            return false
        }
    }
}
