
public struct SwifTeaTheme {
    public struct PanelColors {
        public var foreground: ANSIColor
        public var background: ANSIColor?

        public init(foreground: ANSIColor, background: ANSIColor? = nil) {
            self.foreground = foreground
            self.background = background
        }
    }

    public let name: String
    public let headerPanel: PanelColors
    public let formPanel: PanelColors
    public let primaryText: ANSIColor
    public let mutedText: ANSIColor
    public let accent: ANSIColor
    public let success: ANSIColor
    public let warning: ANSIColor
    public let info: ANSIColor
    public let frameBorder: ANSIColor
    public let background: ANSIColor?
    public let selectionForeground: ANSIColor?
    public let selectionBackground: ANSIColor?
    public let accentGradient: [ANSIColor]
    public let accentGradientSymbol: String

    public init(
        name: String,
        headerPanel: PanelColors,
        formPanel: PanelColors,
        primaryText: ANSIColor,
        mutedText: ANSIColor,
        accent: ANSIColor,
        success: ANSIColor,
        warning: ANSIColor,
        info: ANSIColor,
        frameBorder: ANSIColor,
        background: ANSIColor? = nil,
        selectionForeground: ANSIColor? = nil,
        selectionBackground: ANSIColor? = nil,
        accentGradient: [ANSIColor] = [],
        accentGradientSymbol: String = "▄"
    ) {
        self.name = name
        self.headerPanel = headerPanel
        self.formPanel = formPanel
        self.primaryText = primaryText
        self.mutedText = mutedText
        self.accent = accent
        self.success = success
        self.warning = warning
        self.info = info
        self.frameBorder = frameBorder
        self.background = background
        self.selectionForeground = selectionForeground
        self.selectionBackground = selectionBackground
        self.accentGradient = accentGradient
        self.accentGradientSymbol = accentGradientSymbol
    }
}

public extension SwifTeaTheme {
    static let basic = SwifTeaTheme(
        name: "Basic",
        headerPanel: .init(foreground: .brightWhite, background: .blue),
        formPanel: .init(foreground: .white, background: .brightBlack),
        primaryText: .brightWhite,
        mutedText: .brightBlack,
        accent: .brightCyan,
        success: .brightGreen,
        warning: .brightYellow,
        info: .brightBlue,
        frameBorder: .brightCyan,
        background: .black,
        selectionForeground: .brightWhite,
        selectionBackground: .blue,
        accentGradient: [.brightCyan, .brightBlue, .blue],
        accentGradientSymbol: " "
    )

    static let lumenGlass = SwifTeaTheme(
        name: "Lumen Glass (Truecolor)",
        headerPanel: .init(
            foreground: .trueColor(red: 232, green: 240, blue: 246),
            background: .trueColor(red: 28, green: 44, blue: 56)
        ),
        formPanel: .init(
            foreground: .trueColor(red: 214, green: 224, blue: 232),
            background: .trueColor(red: 12, green: 18, blue: 26)
        ),
        primaryText: .trueColor(red: 226, green: 232, blue: 238),
        mutedText: .trueColor(red: 140, green: 156, blue: 170),
        accent: .trueColor(red: 88, green: 200, blue: 255),
        success: .trueColor(red: 126, green: 236, blue: 204),
        warning: .trueColor(red: 255, green: 202, blue: 120),
        info: .trueColor(red: 120, green: 210, blue: 255),
        frameBorder: .trueColor(red: 90, green: 120, blue: 150),
        background: .trueColor(red: 8, green: 14, blue: 22),
        selectionForeground: .trueColor(red: 232, green: 240, blue: 246),
        selectionBackground: .trueColor(red: 28, green: 72, blue: 104),
        accentGradient: [
            .trueColor(red: 72, green: 182, blue: 255),
            .trueColor(red: 88, green: 200, blue: 255),
            .trueColor(red: 120, green: 220, blue: 220),
            .trueColor(red: 180, green: 212, blue: 236),
            .trueColor(red: 212, green: 232, blue: 244)
        ],
        accentGradientSymbol: "█"
    )
}
