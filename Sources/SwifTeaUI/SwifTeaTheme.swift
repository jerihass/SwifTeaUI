
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
        self.accentGradient = accentGradient
        self.accentGradientSymbol = accentGradientSymbol
    }
}

public extension SwifTeaTheme {
    static let bubbleTeaDark = SwifTeaTheme(
        name: "Bubble Tea (Dark)",
        headerPanel: .init(foreground: .brightWhite, background: .brightMagenta),
        formPanel: .init(foreground: .brightWhite, background: .brightBlack),
        primaryText: .brightWhite,
        mutedText: .brightCyan,
        accent: .brightMagenta,
        success: .brightGreen,
        warning: .brightYellow,
        info: .brightBlue,
        frameBorder: .brightMagenta,
        background: .black,
        accentGradient: [.brightMagenta, .magenta, .brightBlue, .blue, .brightCyan],
        accentGradientSymbol: " "
    )

    static let bubbleTeaLight = SwifTeaTheme(
        name: "Bubble Tea (Light)",
        headerPanel: .init(foreground: .white, background: .brightMagenta),
        formPanel: .init(foreground: .black, background: .brightWhite),
        primaryText: .black,
        mutedText: .magenta,
        accent: .magenta,
        success: .green,
        warning: .red,
        info: .cyan,
        frameBorder: .magenta,
        background: .white,
        accentGradient: [.magenta, .brightMagenta, .brightYellow, .brightCyan, .brightBlue],
        accentGradientSymbol: " "
    )

    static let bubbleTeaNeon = SwifTeaTheme(
        name: "Bubble Tea (Neon)",
        headerPanel: .init(foreground: .brightWhite, background: .brightMagenta),
        formPanel: .init(foreground: .brightWhite, background: .brightCyan),
        primaryText: .brightWhite,
        mutedText: .brightYellow,
        accent: .brightMagenta,
        success: .brightGreen,
        warning: .brightYellow,
        info: .brightCyan,
        frameBorder: .brightMagenta,
        background: .brightBlack,
        accentGradient: [.brightMagenta, .brightYellow, .brightGreen, .brightCyan, .brightBlue],
        accentGradientSymbol: "▄"
    )
}
