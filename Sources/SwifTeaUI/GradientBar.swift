
public struct GradientBar: TUIView {
    public typealias Body = Never

    private struct RGBColor {
        var r: Double
        var g: Double
        var b: Double

        init(_ components: (Int, Int, Int)) {
            self.r = Double(components.0)
            self.g = Double(components.1)
            self.b = Double(components.2)
        }

        func lerped(to other: RGBColor, factor: Double) -> RGBColor {
            RGBColor(
                r: r + (other.r - r) * factor,
                g: g + (other.g - g) * factor,
                b: b + (other.b - b) * factor
            )
        }

        func backgroundCode() -> String {
            return "\u{001B}[48;2;\(Int(r));\(Int(g));\(Int(b))m"
        }

        func foregroundCode() -> String {
            return "\u{001B}[38;2;\(Int(r));\(Int(g));\(Int(b))m"
        }

        private init(r: Double, g: Double, b: Double) {
            self.r = r
            self.g = g
            self.b = b
        }
    }

    private let colors: [ANSIColor]
    private let width: Int
    private let symbol: String

    public init(colors: [ANSIColor], width: Int, symbol: String = " ") {
        self.colors = colors
        self.width = max(1, width)
        self.symbol = symbol.isEmpty ? " " : symbol
    }

    public var body: Never {
        fatalError("GradientBar has no body")
    }

    public func render() -> String {
        guard width > 0 else { return "" }
        let palette = resolvedPalette()
        let stops = palette.count - 1
        var pieces: [String] = []
        pieces.reserveCapacity(width)

        for column in 0..<width {
            let position = Double(column) / Double(max(width - 1, 1))
            let scaled = position * Double(max(stops, 1))
            let lowerIndex = min(Int(scaled.rounded(.down)), palette.count - 1)
            let upperIndex = min(lowerIndex + 1, palette.count - 1)
            let factor = scaled - Double(lowerIndex)
            let color: RGBColor
            if lowerIndex == upperIndex {
                color = palette[lowerIndex]
            } else {
                color = palette[lowerIndex].lerped(to: palette[upperIndex], factor: factor)
            }

            let background = color.backgroundCode()
            if symbol == " " {
                pieces.append(background + " ")
            } else {
                pieces.append(background + color.foregroundCode() + symbol)
            }
        }

        return pieces.joined() + ANSIColor.reset.rawValue
    }

    private func resolvedPalette() -> [RGBColor] {
        let source = colors.isEmpty ? [.reset] : colors
        return source.map { RGBColor($0.rgbComponents) }
    }
}
