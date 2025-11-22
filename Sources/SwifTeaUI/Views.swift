import Foundation

public struct Text: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Text has no body")
    }

    let content: String
    var color: ANSIColor? = nil
    var backgroundColor: ANSIColor? = nil
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderlined: Bool = false

    public init(_ content: String) { self.content = content }

    public func foregroundColor(_ color: ANSIColor) -> Text {
        var copy = self; copy.color = color; return copy
    }

    public func bold() -> Text {
        var copy = self; copy.isBold = true; return copy
    }

    public func italic() -> Text {
        var copy = self; copy.isItalic = true; return copy
    }

    public func underline() -> Text {
        var copy = self; copy.isUnderlined = true; return copy
    }

    public func backgroundColor(_ color: ANSIColor) -> Text {
        var copy = self; copy.backgroundColor = color; return copy
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
        var prefix = ""
        if let color = color {
            prefix += color.rawValue
        }
        if let bg = backgroundColor {
            prefix += bg.backgroundCode
        }
        if isBold {
            prefix += "\u{001B}[1m"
        }
        if isItalic {
            prefix += "\u{001B}[3m"
        }
        if isUnderlined {
            prefix += "\u{001B}[4m"
        }
        guard !prefix.isEmpty else { return content }
        return prefix + content + ANSIColor.reset.rawValue
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

        let rendered = children.map { resolveRenderedView(for: $0) }
        let maxWidth = rendered.map { $0.maxWidth }.max() ?? 0

        var lines: [String] = []
        lines.reserveCapacity(children.count * (spacing + 1))

        for (index, output) in rendered.enumerated() {
            let padded = Self.pad(output, toVisibleWidth: maxWidth, alignment: alignment)
            lines.append(contentsOf: padded.lines)
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
        _ rendered: RenderedView,
        toVisibleWidth width: Int,
        alignment: Alignment
    ) -> RenderedView {
        guard width > 0 else { return rendered }
        if alignment == .leading { return rendered }

        if rendered.lines.isEmpty {
            return RenderedView(lines: [Self.paddedLine("", currentWidth: 0, width: width, alignment: alignment)])
        }

        let padded = rendered.lines.enumerated().map { index, line in
            let currentWidth = rendered.widths[index]
            return Self.paddedLine(line, currentWidth: currentWidth, width: width, alignment: alignment)
        }

        return RenderedView(lines: padded)
    }

    private static func paddedLine(
        _ line: String,
        currentWidth: Int,
        width: Int,
        alignment: Alignment
    ) -> String {
        if alignment == .leading { return line }
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

        let renderedColumns = children.map { resolveRenderedView(for: $0) }
        let columnWidths = renderedColumns.map { $0.maxWidth }
        let columnHeights = renderedColumns.map { $0.height }
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

            for (index, rendered) in renderedColumns.enumerated() {
                let offsetRow = row - verticalOffsets[index]
                let line = (offsetRow >= 0 && offsetRow < rendered.lines.count) ? rendered.lines[offsetRow] : ""
                let padded = Self.pad(
                    line,
                    currentWidth: (offsetRow >= 0 && offsetRow < rendered.widths.count) ? rendered.widths[offsetRow] : 0,
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
        currentWidth: Int,
        toVisibleWidth width: Int,
        alignment: HorizontalAlignment
    ) -> String {
        let currentWidth = currentWidth >= 0 ? currentWidth : visibleWidth(of: line)
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

public struct Group: TUIView {
    private let children: [any TUIView]

    public init(@TUIBuilder _ content: () -> [any TUIView]) {
        self.children = content()
    }

    func makeChildViews() -> [any TUIView] {
        children
    }

    public func render() -> String {
        makeChildViews().map { $0.render() }.joined(separator: "\n")
    }

    public var body: some TUIView { self }
}

public struct Checkbox: TUIView {
    public typealias Body = Never

    public enum Style {
        case square
        case round
    }

    private let isChecked: Bool
    private let isFocused: Bool
    private let label: String
    private let style: Style
    private let accent: ANSIColor
    private let focusStyle: FocusStyle

    public init(
        _ label: String,
        isChecked: Bool,
        isFocused: Bool = false,
        style: Style = .square,
        accent: ANSIColor = .cyan,
        focusStyle: FocusStyle = .default
    ) {
        self.label = label
        self.isChecked = isChecked
        self.isFocused = isFocused
        self.style = style
        self.accent = accent
        self.focusStyle = focusStyle
    }

    public var body: Never {
        fatalError("Checkbox has no body")
    }

    public func render() -> String {
        let marker: String
        switch style {
        case .square:
            marker = isChecked ? "☑" : "☐"
        case .round:
            marker = isChecked ? "⦿" : "⭘"
        }

        var text = "\(marker) \(label)"
        if isFocused {
            text = focusStyle.apply(to: text)
        }
        return accent.rawValue + text + ANSIColor.reset.rawValue
    }
}

public struct RadioButton: TUIView {
    public typealias Body = Never

    private let isSelected: Bool
    private let isFocused: Bool
    private let label: String
    private let accent: ANSIColor
    private let focusStyle: FocusStyle

    public init(
        _ label: String,
        isSelected: Bool,
        isFocused: Bool = false,
        accent: ANSIColor = .cyan,
        focusStyle: FocusStyle = .default
    ) {
        self.label = label
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.accent = accent
        self.focusStyle = focusStyle
    }

    public var body: Never {
        fatalError("RadioButton has no body")
    }

    public func render() -> String {
        let marker = isSelected ? "◉" : "◯"
        var text = "\(marker) \(label)"
        if isFocused {
            text = focusStyle.apply(to: text)
        }
        return accent.rawValue + text + ANSIColor.reset.rawValue
    }
}

fileprivate struct ForEachCacheKey: Hashable {
    let file: String
    let line: UInt
    let idType: ObjectIdentifier
}

final class ForEachCacheStore {
    static var shared = ForEachCacheStore()

    private var storage: [ForEachCacheKey: Any] = [:]
    private let lock = NSLock()

    fileprivate func cache<ID>(for key: ForEachCacheKey) -> ForEachCache<ID> {
        lock.lock()
        defer { lock.unlock() }

        if let cached = storage[key] as? ForEachCache<ID> {
            return cached
        }

        let cache = ForEachCache<ID>()
        storage[key] = cache
        return cache
    }

    func reset() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }
}

private final class ForEachCache<ID: Hashable> {
    struct Entry {
        var fingerprint: AnyHashable?
        var renders: [RenderedView]
    }

    var entries: [ID: Entry] = [:]
    var lastDiffingKey: AnyHashable?

    func reset() {
        entries.removeAll()
        lastDiffingKey = nil
    }
}

public struct ForEach<Data: RandomAccessCollection, ID: Hashable>: TUIView {
    private let data: Data
    private let content: (Data.Element) -> [any TUIView]
    private let idResolver: (Data.Element) -> ID
    private let cacheKey: ForEachCacheKey
    private let cache: ForEachCache<ID>
    private let diffingKey: AnyHashable?
    private let isDiffingEnabled: Bool

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @TUIBuilder content: @escaping (Data.Element) -> [any TUIView],
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        self.init(
            data,
            id: { $0[keyPath: id] },
            diffingKey: nil,
            isDiffingEnabled: false,
            file: String(describing: file),
            line: line,
            content: content
        )
    }

    public init(
        _ data: Data,
        id: @escaping (Data.Element) -> ID,
        @TUIBuilder content: @escaping (Data.Element) -> [any TUIView],
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        self.init(
            data,
            id: id,
            diffingKey: nil,
            isDiffingEnabled: false,
            file: String(describing: file),
            line: line,
            content: content
        )
    }

    private init(
        _ data: Data,
        id: @escaping (Data.Element) -> ID,
        diffingKey: AnyHashable?,
        isDiffingEnabled: Bool,
        file: String,
        line: UInt,
        @TUIBuilder content: @escaping (Data.Element) -> [any TUIView]
    ) {
        self.data = data
        self.content = content
        self.idResolver = id
        self.diffingKey = diffingKey
        self.isDiffingEnabled = isDiffingEnabled

        let cacheKey = ForEachCacheKey(file: String(describing: file), line: line, idType: ObjectIdentifier(ID.self))
        self.cacheKey = cacheKey
        self.cache = ForEachCacheStore.shared.cache(for: cacheKey)
    }

    public func diffing(key: AnyHashable? = nil) -> ForEach {
        ForEach(
            data,
            id: idResolver,
            diffingKey: key,
            isDiffingEnabled: true,
            file: cacheKey.file,
            line: cacheKey.line,
            content: content
        )
    }

    func makeChildViews() -> [any TUIView] {
        guard isDiffingEnabled else {
            cache.reset()
            var views: [any TUIView] = []
            views.reserveCapacity(data.count)
            for element in data {
                _ = idResolver(element)
                views.append(contentsOf: content(element))
            }
            return views
        }

        let invalidateAll = cache.lastDiffingKey != diffingKey
        cache.lastDiffingKey = diffingKey

        if invalidateAll {
            cache.entries.removeAll()
        }

        var nextEntries: [ID: ForEachCache<ID>.Entry] = [:]
        var views: [any TUIView] = []
        views.reserveCapacity(data.count)

        for element in data {
            let id = idResolver(element)
            let fingerprint = element as? AnyHashable

            if let fingerprint,
               let cached = cache.entries[id],
               let cachedFingerprint = cached.fingerprint,
               !invalidateAll,
               cachedFingerprint == fingerprint {
                views.append(contentsOf: cached.renders.map { CachedRenderedView(snapshot: $0) })
                nextEntries[id] = cached
                continue
            }

            let generated = content(element)
            var snapshots: [RenderedView] = []
            snapshots.reserveCapacity(generated.count)

            for view in generated {
                let rendered = resolveRenderedView(for: view)
                snapshots.append(rendered)
                views.append(CachedRenderedView(snapshot: rendered))
            }

            nextEntries[id] = ForEachCache<ID>.Entry(fingerprint: fingerprint, renders: snapshots)
        }

        cache.entries = nextEntries
        return views
    }

    public func render() -> String {
        makeChildViews().map { $0.render() }.joined(separator: "\n")
    }

    public var body: some TUIView { self }
}

public extension ForEach where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        _ data: Data,
        @TUIBuilder content: @escaping (Data.Element) -> [any TUIView],
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        self.init(data, id: { $0.id }, content: content, file: file, line: line)
    }
}

// SwiftUI-esque result builder
@resultBuilder
public struct TUIBuilder {
    public static func buildBlock(_ components: [any TUIView]...) -> [any TUIView] {
        components.flatMap { $0 }
    }

    public static func buildExpression<Data, ID>(_ expression: ForEach<Data, ID>) -> [any TUIView] {
        expression.makeChildViews()
    }

    public static func buildExpression(_ expression: Group) -> [any TUIView] {
        expression.makeChildViews()
    }

    public static func buildExpression<Content: TUIView>(_ expression: Content) -> [any TUIView] {
        [expression]
    }

    public static func buildExpression(_ expression: [any TUIView]) -> [any TUIView] {
        expression
    }

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
