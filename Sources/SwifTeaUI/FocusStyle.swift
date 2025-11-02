import SwifTeaCore

public struct FocusStyle {
    public var indicator: String
    public var color: ANSIColor
    public var bold: Bool

    public init(
        indicator: String = "▌ ",
        color: ANSIColor = .cyan,
        bold: Bool = true
    ) {
        self.indicator = indicator
        self.color = color
        self.bold = bold
    }

    public static let `default` = FocusStyle()

    public func apply(to string: String) -> String {
        let styled: String
        if bold {
            styled = "\u{001B}[1m" + string + ANSIColor.reset.rawValue
        } else {
            styled = string
        }
        let colored = color.rawValue + styled + ANSIColor.reset.rawValue
        if indicator.isEmpty {
            return colored
        }
        return indicator + colored
    }
}
