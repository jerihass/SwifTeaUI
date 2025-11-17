
public struct FocusStyle {
    public var indicator: String
    public var color: ANSIColor?
    public var bold: Bool

    public init(
        indicator: String = "▌ ",
        color: ANSIColor? = .cyan,
        bold: Bool = true
    ) {
        self.indicator = indicator
        self.color = color
        self.bold = bold
    }

    public static let `default` = FocusStyle(indicator: "", color: .cyan, bold: true)

    public func apply(to string: String) -> String {
        var styled = string
        if bold {
            styled = "\u{001B}[1m" + styled + ANSIColor.reset.rawValue
        }
        if let color {
            styled = color.rawValue + styled + ANSIColor.reset.rawValue
        }
        if indicator.isEmpty {
            return styled
        }
        return indicator + styled
    }
}
