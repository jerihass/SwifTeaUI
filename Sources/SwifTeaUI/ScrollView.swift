
public struct ScrollView<Content: TUIView>: TUIView {
    public enum Axis {
        case vertical
        case horizontal
    }

    public enum ScrollIndicatorVisibility {
        case never
        case automatic
    }

    public struct ScrollIndicators {
        public var leading: String
        public var trailing: String

        public init(leading: String, trailing: String) {
            self.leading = leading
            self.trailing = trailing
        }

        public static var verticalArrows: ScrollIndicators {
            ScrollIndicators(leading: "↑", trailing: "↓")
        }

        public static var horizontalArrows: ScrollIndicators {
            ScrollIndicators(leading: "←", trailing: "→")
        }
    }

    public typealias Body = Never

    private let axis: Axis
    private let viewport: Int
    private let offset: Binding<Int>
    private let pinnedToBottom: Binding<Bool>?
    private let contentLength: Binding<Int>?
    private var activeLine: Binding<Int>?
    private var followActiveLine: Binding<Bool>?
    private var indicatorVisibility: ScrollIndicatorVisibility
    private var indicatorSymbols: ScrollIndicators?
    private var isScrollDisabled: Bool
    private let content: Content

    public init(
        _ axis: Axis = .vertical,
        viewport: Int,
        offset: Binding<Int>,
        pinnedToBottom: Binding<Bool>? = nil,
        contentLength: Binding<Int>? = nil,
        activeLine: Binding<Int>? = nil,
        followActiveLine: Binding<Bool>? = nil,
        content: () -> Content
    ) {
        self.axis = axis
        self.viewport = max(1, viewport)
        self.offset = offset
        self.pinnedToBottom = pinnedToBottom
        self.contentLength = contentLength
        self.activeLine = activeLine
        self.followActiveLine = followActiveLine
        self.indicatorVisibility = .never
        self.indicatorSymbols = nil
        self.isScrollDisabled = false
        self.content = content()
    }

    public var body: Never {
        fatalError("ScrollView has no body")
    }

    public func render() -> String {
        switch axis {
        case .vertical:
            return renderVertical()
        case .horizontal:
            return renderHorizontal()
        }
    }

    public func scrollIndicators(
        _ visibility: ScrollIndicatorVisibility,
        symbols: ScrollIndicators? = nil
    ) -> ScrollView {
        var copy = self
        copy.indicatorVisibility = visibility
        copy.indicatorSymbols = symbols
        return copy
    }

    public func scrollDisabled(_ disabled: Bool = true) -> ScrollView {
        var copy = self
        copy.isScrollDisabled = disabled
        return copy
    }

    public func followingActiveLine(
        _ line: Binding<Int>,
        enabled: Binding<Bool>? = nil
    ) -> ScrollView {
        var copy = self
        copy.activeLine = line
        copy.followActiveLine = enabled ?? Binding.constant(true)
        return copy
    }

    private func renderVertical() -> String {
        var lines = content.render().splitLinesPreservingEmpty()
        if lines.isEmpty {
            lines = [""]
        }

        contentLength?.wrappedValue = lines.count
        let maxOffset = max(0, lines.count - viewport)

        var resolvedOffset = clamp(offset: offset.wrappedValue, max: maxOffset)
        if !isScrollDisabled, pinnedToBottom?.wrappedValue == true {
            resolvedOffset = maxOffset
        } else if !isScrollDisabled,
                  let shouldFollow = followActiveLine?.wrappedValue,
                  shouldFollow,
                  let activeLine = activeLine?.wrappedValue {
            let clampedActive = max(0, min(activeLine, lines.count - 1))
            if clampedActive < resolvedOffset {
                resolvedOffset = clampedActive
            } else if clampedActive >= resolvedOffset + viewport {
                resolvedOffset = clampedActive - viewport + 1
            }
            resolvedOffset = clamp(offset: resolvedOffset, max: maxOffset)
        }

        if !isScrollDisabled, offset.wrappedValue != resolvedOffset {
            offset.wrappedValue = resolvedOffset
        }

        var visible: [String] = []
        visible.reserveCapacity(viewport)

        for index in 0..<viewport {
            let source = resolvedOffset + index
            if source < lines.count {
                visible.append(lines[source])
            } else {
                visible.append("")
            }
        }

        if indicatorVisibility == .automatic {
            visible = applyVerticalIndicators(
                to: visible,
                offset: resolvedOffset,
                maxOffset: maxOffset
            )
        }

        return visible.joined(separator: "\n")
    }

    private func renderHorizontal() -> String {
        var lines = content.render().splitLinesPreservingEmpty()
        if lines.isEmpty {
            lines = [""]
        }

        let widths = lines.map { HStack.visibleWidth(of: $0) }
        let contentWidth = widths.max() ?? 0
        contentLength?.wrappedValue = contentWidth
        let maxOffset = max(0, contentWidth - viewport)

        var resolvedOffset = clamp(offset: offset.wrappedValue, max: maxOffset)
        if !isScrollDisabled, pinnedToBottom?.wrappedValue == true {
            resolvedOffset = maxOffset
        }
        resolvedOffset = clamp(offset: resolvedOffset, max: maxOffset)

        if !isScrollDisabled, offset.wrappedValue != resolvedOffset {
            offset.wrappedValue = resolvedOffset
        }

        var visible = lines.map { sliceLine($0, offset: resolvedOffset, width: viewport) }
        if indicatorVisibility == .automatic {
            visible = applyHorizontalIndicators(
                to: visible,
                offset: resolvedOffset,
                maxOffset: maxOffset
            )
        }
        return visible.joined(separator: "\n")
    }

    private func sliceLine(_ line: String, offset: Int, width: Int) -> String {
        guard width > 0 else { return "" }

        var visibleIndex = 0
        var produced = 0
        var capturing = false
        var result = ""
        var pendingSequences = ""
        var index = line.startIndex
        var inEscape = false
        var currentSequence = ""

        while index < line.endIndex {
            let character = line[index]
            if inEscape {
                currentSequence.append(character)
                if character.isANSISequenceTerminator {
                    inEscape = false
                    if capturing {
                        result.append(currentSequence)
                    } else {
                        pendingSequences.append(currentSequence)
                    }
                    currentSequence.removeAll(keepingCapacity: true)
                }
            } else if character == "\u{001B}" {
                inEscape = true
                currentSequence = "\u{001B}"
            } else {
                if visibleIndex >= offset, produced < width {
                    if !capturing {
                        capturing = true
                        if !pendingSequences.isEmpty {
                            result.append(pendingSequences)
                            pendingSequences.removeAll(keepingCapacity: true)
                        }
                    }
                    result.append(character)
                    produced += 1
                }
                visibleIndex += 1
            }
            index = line.index(after: index)
        }

        if !capturing {
            return String(repeating: " ", count: width)
        }

        let currentWidth = HStack.visibleWidth(of: result)
        if currentWidth < width {
            result = insertPadding(result, padding: width - currentWidth)
        }
        return result
    }

    private func applyVerticalIndicators(
        to lines: [String],
        offset: Int,
        maxOffset: Int
    ) -> [String] {
        guard maxOffset > 0 else { return lines }
        let symbols = indicatorSymbols ?? .verticalArrows
        let leadingWidth = HStack.visibleWidth(of: symbols.leading)
        let trailingWidth = HStack.visibleWidth(of: symbols.trailing)
        let columnWidth = max(leadingWidth, trailingWidth)
        guard columnWidth > 0 else { return lines }

        let empty = String(repeating: " ", count: columnWidth)
        let leadingIndicator = padIndicator(symbols.leading, to: columnWidth)
        let trailingIndicator = padIndicator(symbols.trailing, to: columnWidth)

        if lines.count == 1 {
            let indicator: String
            if offset > 0 {
                indicator = leadingIndicator
            } else if offset < maxOffset {
                indicator = trailingIndicator
            } else {
                indicator = empty
            }
            return [indicator + lines[0]]
        }

        return lines.enumerated().map { index, line in
            if index == 0 {
                return (offset > 0 ? leadingIndicator : empty) + line
            } else if index == lines.count - 1 {
                return (offset < maxOffset ? trailingIndicator : empty) + line
            } else {
                return empty + line
            }
        }
    }

    private func applyHorizontalIndicators(
        to lines: [String],
        offset: Int,
        maxOffset: Int
    ) -> [String] {
        guard maxOffset > 0 else { return lines }
        let symbols = indicatorSymbols ?? .horizontalArrows
        let leadingWidth = HStack.visibleWidth(of: symbols.leading)
        let trailingWidth = HStack.visibleWidth(of: symbols.trailing)
        let emptyLeading = leadingWidth > 0 ? String(repeating: " ", count: leadingWidth) : ""
        let emptyTrailing = trailingWidth > 0 ? String(repeating: " ", count: trailingWidth) : ""
        let leadingIndicator = padIndicator(symbols.leading, to: leadingWidth)
        let trailingIndicator = padIndicator(symbols.trailing, to: trailingWidth)

        return lines.map { line in
            let prefix = leadingWidth > 0
                ? (offset > 0 ? leadingIndicator : emptyLeading)
                : ""
            let suffix = trailingWidth > 0
                ? (offset < maxOffset ? trailingIndicator : emptyTrailing)
                : ""
            return prefix + line + suffix
        }
    }

    private func insertPadding(_ string: String, padding: Int) -> String {
        guard padding > 0 else { return string }
        let extra = String(repeating: " ", count: padding)

        guard string.hasSuffix(ANSIColor.reset.rawValue) else {
            return string + extra
        }

        var trimmed = string
        trimmed.removeLast(ANSIColor.reset.rawValue.count)
        return trimmed + extra + ANSIColor.reset.rawValue
    }

    private func padIndicator(_ string: String, to width: Int) -> String {
        guard width > 0 else { return "" }
        let visible = HStack.visibleWidth(of: string)
        guard visible < width else { return string }
        return string + String(repeating: " ", count: width - visible)
    }

    private func clamp(offset value: Int, max: Int) -> Int {
        if value < 0 { return 0 }
        if value > max { return max }
        return value
    }
}
