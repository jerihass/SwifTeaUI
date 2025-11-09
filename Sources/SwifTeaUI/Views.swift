import Foundation
import SwifTeaCore

public struct Text: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Text has no body")
    }

    let content: String
    var color: ANSIColor? = nil
    var isBold: Bool = false

    public init(_ content: String) { self.content = content }

    public func foregroundColor(_ color: ANSIColor) -> Text {
        var copy = self; copy.color = color; return copy
    }

    public func bold() -> Text {
        var copy = self; copy.isBold = true; return copy
    }

    @available(*, deprecated, message: "Use foregroundColor(_: ) to mirror SwiftUI naming.")
    public func foreground(_ color: ANSIColor) -> Text {
        foregroundColor(color)
    }

    @available(*, deprecated, message: "Use bold() to mirror SwiftUI naming.")
    public func bolded() -> Text {
        bold()
    }

    public func render() -> String {
        var s = content
        if isBold { s = "\u{001B}[1m" + s + ANSIColor.reset.rawValue }
        if let c = color { s = c.rawValue + s + ANSIColor.reset.rawValue }
        return s
    }
}

public struct VStack: TUIView {
    public enum Alignment {
        case leading
        case center
        case trailing
    }

    public enum VerticalAlignment {
        case top
        case center
        case bottom
    }

    public typealias Body = Never

    public var body: Never {
        fatalError("VStack has no body")
    }

    let children: [any TUIView]
    let spacing: Int
    let alignment: Alignment
    let verticalAlignment: VerticalAlignment
    let height: Int?

    public init(
        spacing: Int = 0,
        alignment: Alignment = .leading,
        verticalAlignment: VerticalAlignment = .top,
        @TUIBuilder _ content: () -> [any TUIView]
    ) {
        self.init(
            children: content(),
            spacing: max(0, spacing),
            alignment: alignment,
            verticalAlignment: verticalAlignment,
            height: nil
        )
    }

    private init(
        children: [any TUIView],
        spacing: Int,
        alignment: Alignment,
        verticalAlignment: VerticalAlignment,
        height: Int?
    ) {
        self.children = children
        self.spacing = spacing
        self.alignment = alignment
        self.verticalAlignment = verticalAlignment
        self.height = height
    }

    public func frame(height: Int?, alignment verticalAlignment: VerticalAlignment? = nil) -> VStack {
        let sanitizedHeight = height.flatMap { max(0, $0) }
        return VStack(
            children: children,
            spacing: spacing,
            alignment: alignment,
            verticalAlignment: verticalAlignment ?? self.verticalAlignment,
            height: sanitizedHeight
        )
    }

    public func render() -> String {
        guard !children.isEmpty else { return "" }

        let rendered = children.map { $0.render() }
        let widths = rendered.map { string -> Int in
            string.splitLinesPreservingEmpty().map { HStack.visibleWidth(of: $0) }.max() ?? 0
        }
        let maxWidth = widths.max() ?? 0

        var lines: [String] = []
        lines.reserveCapacity(children.count * (spacing + 1))

        for (index, output) in rendered.enumerated() {
            let padded = Self.pad(output, toVisibleWidth: maxWidth, alignment: alignment)
            lines.append(padded)
            if spacing > 0 && index < rendered.count - 1 {
                for _ in 0..<spacing {
                    lines.append("")
                }
            }
        }

        let adjusted = applyVerticalAlignment(to: lines)
        return adjusted.joined(separator: "\n")
    }

    private func applyVerticalAlignment(to lines: [String]) -> [String] {
        guard let targetHeight = height, targetHeight > lines.count else {
            return lines
        }

        let missing = targetHeight - lines.count
        switch verticalAlignment {
        case .top:
            return lines + Array(repeating: "", count: missing)
        case .bottom:
            return Array(repeating: "", count: missing) + lines
        case .center:
            let leading = missing / 2
            let trailing = missing - leading
            return Array(repeating: "", count: leading) + lines + Array(repeating: "", count: trailing)
        }
    }

    private static func pad(
        _ string: String,
        toVisibleWidth width: Int,
        alignment: Alignment
    ) -> String {
        guard width > 0 else { return string }
        if alignment == .leading { return string }

        let lines = string.splitLinesPreservingEmpty()
        if lines.isEmpty {
            return Self.paddedLine("", width: width, alignment: alignment)
        }

        let padded = lines.map { line in
            Self.paddedLine(line, width: width, alignment: alignment)
        }

        return padded.joined(separator: "\n")
    }

    private static func paddedLine(
        _ line: String,
        width: Int,
        alignment: Alignment
    ) -> String {
        if alignment == .leading { return line }
        let currentWidth = HStack.visibleWidth(of: line)
        guard currentWidth < width else { return line }
        let padding = width - currentWidth

        switch alignment {
        case .leading:
            return line + String(repeating: " ", count: padding)
        case .trailing:
            return String(repeating: " ", count: padding) + line
        case .center:
            let leading = padding / 2
            let trailing = padding - leading
            return String(repeating: " ", count: leading) + line + String(repeating: " ", count: trailing)
        }
    }
}


public struct HStack: TUIView {
    public enum HorizontalAlignment {
        case leading
        case center
        case trailing
    }

    public enum VerticalAlignment {
        case top
        case center
        case bottom
    }

    public typealias Body = Never

    public var body: Never {
        fatalError("HStack has no body")
    }

    let children: [any TUIView]
    let spacing: Int
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment

    public init(
        spacing: Int = 3,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .top,
        @TUIBuilder _ content: () -> [any TUIView]
    ) {
        self.children = content()
        self.spacing = max(0, spacing)
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
    }

    public func render() -> String {
        guard !children.isEmpty else { return "" }

        let renderedColumns = children.map { $0.render().splitLinesPreservingEmpty() }
        let columnWidths = renderedColumns.map { $0.map(Self.visibleWidth(of:)).max() ?? 0 }
        let columnHeights = renderedColumns.map(\.count)
        let maxRows = columnHeights.max() ?? 0
        let spacingString = String(repeating: " ", count: spacing)

        let verticalOffsets = columnHeights.map { height -> Int in
            guard height < maxRows else { return 0 }
            switch verticalAlignment {
            case .top:
                return 0
            case .center:
                return (maxRows - height) / 2
            case .bottom:
                return maxRows - height
            }
        }

        var rows: [String] = []
        rows.reserveCapacity(maxRows)

        for row in 0..<maxRows {
            var pieces: [String] = []
            pieces.reserveCapacity(children.count)

            for (index, lines) in renderedColumns.enumerated() {
                let offsetRow = row - verticalOffsets[index]
                let line = (offsetRow >= 0 && offsetRow < lines.count) ? lines[offsetRow] : ""
                let padded = Self.pad(
                    line,
                    toVisibleWidth: columnWidths[index],
                    alignment: horizontalAlignment
                )
                pieces.append(padded)
            }

            rows.append(pieces.joined(separator: spacingString))
        }

        return rows.joined(separator: "\n")
    }

    static func visibleWidth(of string: String) -> Int {
        var width = 0
        var index = string.startIndex
        var inEscape = false

        while index < string.endIndex {
            let character = string[index]

            if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
            } else if character == "\u{001B}" {
                inEscape = true
            } else {
                width += 1
            }

            index = string.index(after: index)
        }

        return width
    }

    private static func pad(
        _ line: String,
        toVisibleWidth width: Int,
        alignment: HorizontalAlignment
    ) -> String {
        let currentWidth = visibleWidth(of: line)
        guard currentWidth < width else { return line }

        let padding = width - currentWidth
        switch alignment {
        case .leading:
            return line + String(repeating: " ", count: padding)
        case .trailing:
            return String(repeating: " ", count: padding) + line
        case .center:
            let leading = padding / 2
            let trailing = padding - leading
            return String(repeating: " ", count: leading) + line + String(repeating: " ", count: trailing)
        }
    }
}

extension String {
    public func splitLinesPreservingEmpty() -> [String] {
        if isEmpty { return [""] }
        var lines: [String] = []
        lines.reserveCapacity(count / 8)

        var current = ""
        for character in self {
            if character == "\n" {
                lines.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        lines.append(current)
        return lines
    }
}

extension Character {
    public var isANSISequenceTerminator: Bool {
        switch self {
        case "a"..."z", "A"..."Z":
            return true
        default:
            return false
        }
    }
}

public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content: TUIView>: TUIView {
    private let data: Data
    private let content: (Data.Element) -> Content
    private let idResolver: (Data.Element) -> ID

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        content: @escaping (Data.Element) -> Content
    ) {
        self.init(data, id: { $0[keyPath: id] }, content: content)
    }

    public init(
        _ data: Data,
        id: @escaping (Data.Element) -> ID,
        content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.idResolver = id
    }

    public func render() -> String {
        var renderedItems: [String] = []
        renderedItems.reserveCapacity(data.count)
        for element in data {
            _ = idResolver(element) // ensures typechecked; reserved for future diffing
            renderedItems.append(content(element).render())
        }
        return renderedItems.joined(separator: "\n")
    }

    public var body: some TUIView { self }
}

public extension ForEach where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        _ data: Data,
        content: @escaping (Data.Element) -> Content
    ) {
        self.init(data, id: { $0.id }, content: content)
    }
}

// SwiftUI-esque result builder
@resultBuilder
public struct TUIBuilder {
    public static func buildBlock(_ components: any TUIView...) -> [any TUIView] { components }

    public static func buildOptional(_ component: [any TUIView]?) -> [any TUIView] {
        component ?? []
    }

    public static func buildEither(first component: [any TUIView]) -> [any TUIView] {
        component
    }

    public static func buildEither(second component: [any TUIView]) -> [any TUIView] {
        component
    }

    public static func buildArray(_ components: [[any TUIView]]) -> [any TUIView] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [any TUIView]) -> [any TUIView] {
        component
    }
}
