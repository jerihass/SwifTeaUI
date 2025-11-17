
public struct StatusBar: TUIView {
    public typealias Body = Never

    public struct Segment {
        public var text: String
        public var color: ANSIColor?

        public init(_ text: String, color: ANSIColor? = nil) {
            self.text = text
            self.color = color
        }
    }

    public var body: Never {
        fatalError("StatusBar has no body")
    }

    private let width: Int?
    private let leading: [Segment]
    private let trailing: [Segment]
    private let segmentSpacing: String
    private let groupSpacing: String

    public init(
        width: Int? = nil,
        segmentSpacing: String = " ",
        groupSpacing: String = "  ",
        leading: [Segment] = [],
        trailing: [Segment] = []
    ) {
        if let width, width > 0 {
            self.width = width
        } else {
            self.width = nil
        }
        self.segmentSpacing = segmentSpacing
        self.groupSpacing = groupSpacing
        self.leading = leading
        self.trailing = trailing
    }

    public func render() -> String {
        let leadingString = join(segments: leading)
        let trailingString = join(segments: trailing)

        if let width {
            let leadingWidth = Self.visibleWidth(of: leadingString)
            let trailingWidth = Self.visibleWidth(of: trailingString)

            if trailingWidth == 0 {
                return pad(leadingString, to: width)
            }

            let available = width - leadingWidth - trailingWidth
            if available >= 1 {
                return leadingString + String(repeating: " ", count: available) + trailingString
            }

            // Fallback to unpadded concatenation when width is too small
            return fallbackJoin(leading: leadingString, trailing: trailingString)
        }

        return fallbackJoin(leading: leadingString, trailing: trailingString)
    }

    private func join(segments: [Segment]) -> String {
        guard !segments.isEmpty else { return "" }
        return segments.map(render).joined(separator: segmentSpacing)
    }

    private func render(_ segment: Segment) -> String {
        guard let color = segment.color else {
            return segment.text
        }
        return color.rawValue + segment.text + ANSIColor.reset.rawValue
    }

    private func pad(_ string: String, to width: Int) -> String {
        let current = Self.visibleWidth(of: string)
        guard current < width else { return string }
        return string + String(repeating: " ", count: width - current)
    }

    private func fallbackJoin(leading: String, trailing: String) -> String {
        switch (leading.isEmpty, trailing.isEmpty) {
        case (true, true):
            return ""
        case (false, true):
            return leading
        case (true, false):
            return trailing
        case (false, false):
            return leading + groupSpacing + trailing
        }
    }

    private static func visibleWidth(of string: String) -> Int {
        var count = 0
        var iterator = string.makeIterator()
        var inEscape = false

        while let next = iterator.next() {
            if inEscape {
                if next.isANSISequenceTerminator {
                    inEscape = false
                }
            } else if next == "\u{001B}" {
                inEscape = true
            } else {
                count += 1
            }
        }

        return count
    }
}
