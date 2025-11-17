import Foundation

public struct Spinner: TUIView {
    public struct Style: Equatable {
        public let frames: [String]
        public let interval: TimeInterval
        public let idle: String

        public init(frames: [String], interval: TimeInterval = 0.12, idle: String = " ") {
            let sanitized = frames.filter { !$0.isEmpty }
            self.frames = sanitized.isEmpty ? [" "] : sanitized
            self.interval = max(interval, 0.01)
            self.idle = idle
        }

        public static let ascii = Style(frames: ["-", "\\", "|", "/"])
        public static let braille = Style(frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"])
        public static let dots = Style(frames: [".  ", ".. ", "...", " ..", "  ."], idle: "   ")
        public static let line = Style(frames: ["⎺", "⎻", "⎼", "⎽"], idle: " ")
    }

    public typealias Body = Never

    public var body: Never {
        fatalError("Spinner has no body")
    }

    private let label: String?
    private let style: Style
    private let color: ANSIColor?
    private let isBold: Bool
    private let isSpinning: Bool

    public init(
        label: String? = nil,
        style: Style = .ascii,
        color: ANSIColor? = nil,
        isBold: Bool = false,
        isSpinning: Bool = true
    ) {
        self.label = label
        self.style = style
        self.color = color
        self.isBold = isBold
        self.isSpinning = isSpinning
    }

    public func render() -> String {
        guard isSpinning else {
            return style.idle
        }

        let glyph = SpinnerTimeline.shared.frame(for: style)
        let spinnerGlyph = format(glyph, bold: isBold)

        guard let label else {
            return spinnerGlyph
        }

        let labelGlyph = format(label, bold: false)
        return spinnerGlyph + " " + labelGlyph
    }

    private func format(_ text: String, bold: Bool) -> String {
        if color == nil && !bold {
            return text
        }

        var prefix = ""
        if let color {
            prefix += color.rawValue
        }
        if bold {
            prefix += "\u{001B}[1m"
        }

        return prefix + text + ANSIColor.reset.rawValue
    }
}

public struct SpinnerTimeline {
    public static var shared = SpinnerTimeline()

    public var timeProvider: () -> TimeInterval = {
        ProcessInfo.processInfo.systemUptime
    }

    public init() {}

    public func frame(for style: Spinner.Style) -> String {
        guard !style.frames.isEmpty else { return style.idle }

        let interval = max(style.interval, 0.01)
        let elapsed = max(0, timeProvider())

        let index = Int(elapsed / interval)
        let frameIndex = index % style.frames.count

        return style.frames[frameIndex]
    }
}
