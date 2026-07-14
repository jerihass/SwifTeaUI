import Foundation

public struct ListRowSeparatorStyle: Sendable {
    public enum Style: Sendable {
        case none
        case dashed
        case line(Character)
    }

    let style: Style
    let color: ANSIColor?

    public static let none = ListRowSeparatorStyle(style: .none, color: nil)

    public static func line(color: ANSIColor? = .brightBlack) -> ListRowSeparatorStyle {
        ListRowSeparatorStyle(style: .line("─"), color: color)
    }

    public static func dashed(color: ANSIColor? = .brightBlack) -> ListRowSeparatorStyle {
        ListRowSeparatorStyle(style: .dashed, color: color)
    }
}

@resultBuilder
public enum ListRowBuilder {
    public static func buildBlock<T: TUIView>(_ components: T...) -> [AnyTUIView] {
        components.map { AnyTUIView($0) }
    }
}

public struct ListSelectionConfiguration<ID: Hashable> {
    public enum Mode {
        case single(Binding<ID?>)
        case multiple(Binding<Set<ID>>)
    }

    let mode: Mode
    let focused: Binding<ID?>?
    let selectionStyle: TableRowStyle
    let focusedStyle: TableRowStyle

    public init(
        mode: Mode,
        focused: Binding<ID?>? = nil,
        selectionStyle: TableRowStyle = .selected(),
        focusedStyle: TableRowStyle = .focused()
    ) {
        self.mode = mode
        self.focused = focused
        self.selectionStyle = selectionStyle
        self.focusedStyle = focusedStyle
    }

    public static func single(
        _ binding: Binding<ID?>,
        focused: Binding<ID?>? = nil,
        selectionStyle: TableRowStyle = .selected(),
        focusedStyle: TableRowStyle = .focused()
    ) -> ListSelectionConfiguration<ID> {
        ListSelectionConfiguration(
            mode: .single(binding),
            focused: focused,
            selectionStyle: selectionStyle,
            focusedStyle: focusedStyle
        )
    }

    public static func multiple(
        _ binding: Binding<Set<ID>>,
        focused: Binding<ID?>? = nil,
        selectionStyle: TableRowStyle = .selected(),
        focusedStyle: TableRowStyle = .focused()
    ) -> ListSelectionConfiguration<ID> {
        ListSelectionConfiguration(
            mode: .multiple(binding),
            focused: focused,
            selectionStyle: selectionStyle,
            focusedStyle: focusedStyle
        )
    }

    func isSelected(_ id: ID) -> Bool {
        switch mode {
        case .single(let binding):
            return binding.wrappedValue == id
        case .multiple(let binding):
            return binding.wrappedValue.contains(id)
        }
    }

    func isFocused(_ id: ID) -> Bool {
        guard let focused else { return false }
        return focused.wrappedValue == id
    }
}

public struct List<Data: RandomAccessCollection, ID: Hashable>: TUIView {
    public typealias Element = Data.Element

    private let data: Data
    private let rowBuilder: (Element) -> [AnyTUIView]
    private let separatorStyle: ListRowSeparatorStyle
    private let rowSpacing: Int
    private let idResolver: (Element) -> ID
    private let selectionConfiguration: ListSelectionConfiguration<ID>?

    public init(
        _ data: Data,
        id: KeyPath<Element, ID>,
        rowSpacing: Int = 0,
        separator: ListRowSeparatorStyle = .line(),
        selection: ListSelectionConfiguration<ID>? = nil,
        @ListRowBuilder rows: @escaping (Element) -> [AnyTUIView]
    ) {
        self.init(
            data,
            id: { $0[keyPath: id] },
            rowSpacing: rowSpacing,
            separator: separator,
            selection: selection,
            rows: rows
        )
    }

    public init(
        _ data: Data,
        id: @escaping (Element) -> ID,
        rowSpacing: Int = 0,
        separator: ListRowSeparatorStyle = .line(),
        selection: ListSelectionConfiguration<ID>? = nil,
        @ListRowBuilder rows: @escaping (Element) -> [AnyTUIView]
    ) {
        self.data = data
        self.rowBuilder = rows
        self.separatorStyle = separator
        self.rowSpacing = max(0, rowSpacing)
        self.idResolver = id
        self.selectionConfiguration = selection
    }

    public var body: some TUIView { self }

    public func render() -> String {
        var renderedRows: [RenderedRow] = []
        renderedRows.reserveCapacity(data.count)
        var maxWidth = 0

        for element in data {
            let id = idResolver(element)
            let rowViews = rowBuilder(element)
            var lines: [String] = []
            var widths: [Int] = []
            lines.reserveCapacity(rowViews.count)
            widths.reserveCapacity(rowViews.count)

            for view in rowViews {
                let rendered = resolveRenderedView(for: view)
                lines.append(contentsOf: rendered.lines)
                widths.append(contentsOf: rendered.widths)
            }

            let row = RenderedRow(
                id: id,
                lines: lines,
                widths: widths,
                style: resolvedStyle(for: id)
            )
            renderedRows.append(row)
            maxWidth = max(maxWidth, row.maxWidth)
        }

        let resolvedRows = renderedRows.map { row in
            ResolvedRow(row: row, style: row.style)
        }
        let reservedLeading = resolvedRows.map(\.gutterLeading).max() ?? 0
        let reservedTrailing = resolvedRows.map(\.gutterTrailing).max() ?? 0
        let rowWidth = maxWidth + reservedLeading + reservedTrailing

        var lines: [String] = []
        for (index, row) in resolvedRows.enumerated() {
            if rowSpacing > 0 && index > 0 {
                lines.append(contentsOf: Array(repeating: "", count: rowSpacing))
            }

            for line in row.row.lines {
                lines.append(
                    RowStyleRenderer.apply(
                        style: row.style,
                        to: line,
                        totalWidth: rowWidth,
                        reservedLeading: reservedLeading,
                        reservedTrailing: reservedTrailing
                    )
                )
            }

            if index < resolvedRows.count - 1, let separatorLine = separator(maxWidth: maxWidth) {
                lines.append(
                    RowStyleRenderer.apply(
                        style: nil,
                        to: separatorLine,
                        totalWidth: rowWidth,
                        reservedLeading: reservedLeading,
                        reservedTrailing: reservedTrailing
                    )
                )
            }
        }

        return lines.joined(separator: "\n")
    }

    private func separator(maxWidth: Int) -> String? {
        switch separatorStyle.style {
        case .none:
            return nil
        case .dashed:
            let pattern = "- "
            var line = ""
            while HStack.visibleWidth(of: line) < maxWidth {
                line += pattern
            }
            line = line.padded(toVisibleWidth: maxWidth)
            if let color = separatorStyle.color {
                return color.rawValue + line + ANSIColor.reset.rawValue
            }
            return line
        case .line(let character):
            let line = String(repeating: character, count: maxWidth)
            if let color = separatorStyle.color {
                return color.rawValue + line + ANSIColor.reset.rawValue
            }
            return line
        }
    }

    private func resolvedStyle(for id: ID) -> TableRowStyle? {
        guard let selectionConfiguration else { return nil }
        var style: TableRowStyle?
        if selectionConfiguration.isSelected(id) {
            style = selectionConfiguration.selectionStyle
        }
        if selectionConfiguration.isFocused(id) {
            style = style?.merging(selectionConfiguration.focusedStyle) ?? selectionConfiguration.focusedStyle
        }
        return style
    }

    private struct RenderedRow {
        let id: ID
        let lines: [String]
        let widths: [Int]
        let style: TableRowStyle?

        var maxWidth: Int {
            widths.max() ?? 0
        }
    }

    private struct ResolvedRow {
        let row: RenderedRow
        let style: TableRowStyle?

        var gutterLeading: Int {
            RowStyleRenderer.gutterLeading(for: style)
        }

        var gutterTrailing: Int {
            RowStyleRenderer.gutterTrailing(for: style)
        }
    }
}
