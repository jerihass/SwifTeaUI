import Foundation

public struct ProgressMeter: TUIView {
    public struct Style {
        public var fill: Character
        public var empty: Character
        public var color: ANSIColor?

        public init(fill: Character = "#", empty: Character = " ", color: ANSIColor? = nil) {
            self.fill = fill
            self.empty = empty
            self.color = color
        }

        public static let solid = Style()
        public static let ascii = Style(fill: "=", empty: " ")
        public static let dotted = Style(fill: "#", empty: ".")
        public static let shaded = Style(fill: "█", empty: "░")

        public static func tinted(_ color: ANSIColor, fill: Character = "#", empty: Character = " ") -> Style {
            Style(fill: fill, empty: empty, color: color)
        }
    }

    public typealias Body = Never

    private let value: Double
    private let width: Int
    private let style: Style
    private let showsPercentage: Bool

    public init(
        value: Double,
        width: Int = 16,
        style: Style = .solid,
        showsPercentage: Bool = true
    ) {
        self.value = value
        self.width = max(1, width)
        self.style = style
        self.showsPercentage = showsPercentage
    }

    public var body: Never {
        fatalError("ProgressMeter has no body")
    }

    public func render() -> String {
        let clamped = min(max(value, 0), 1)
        var filled = Int(clamped * Double(width))
        if clamped >= 1 {
            filled = width
        }
        let emptyCount = max(0, width - filled)

        let filledSection = String(repeating: style.fill, count: filled)
        let emptySection = String(repeating: style.empty, count: emptyCount)

        var bar = "[\(filledSection)\(emptySection)]"
        if let color = style.color {
            bar = color.rawValue + bar + ANSIColor.reset.rawValue
        }

        guard showsPercentage else { return bar }

        let percent = Int((clamped * 100).rounded())
        let formatted = String(format: "%3d%%", percent)
        return "\(bar) \(formatted)"
    }
}
