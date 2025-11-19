import Foundation

public struct TableColumn<Row> {
    public enum Width {
        case fixed(Int)
        case fitContent
        case flex(min: Int = 0, max: Int? = nil)
    }

    public enum Alignment {
        case leading
        case center
        case trailing
    }

    let width: Width
    let alignment: Alignment
    let headerBuilder: () -> [any TUIView]
    let cellBuilder: (Row) -> [any TUIView]

    public init(
        _ title: String? = nil,
        width: Width = .fitContent,
        alignment: Alignment = .leading,
        @TUIBuilder _ content: @escaping (Row) -> [any TUIView]
    ) {
        self.init(
            width: width,
            alignment: alignment,
            header: {
                guard let title else { return [] }
                return [Text(title).bold()]
            },
            content
        )
    }

    public init(
        width: Width = .fitContent,
        alignment: Alignment = .leading,
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder _ content: @escaping (Row) -> [any TUIView]
    ) {
        self.width = width
        self.alignment = alignment
        self.headerBuilder = header
        self.cellBuilder = content
    }
}

public struct TableRowStyle {
    public struct Border {
        public var leading: String
        public var trailing: String

        public init(leading: String = "│ ", trailing: String = " │") {
            self.leading = leading
            self.trailing = trailing
        }
    }

    public var foregroundColor: ANSIColor?
    public var backgroundColor: ANSIColor?
    public var isBold: Bool
    public var isUnderlined: Bool
    public var isDimmed: Bool
    public var isReversed: Bool
    public var border: Border?

    public init(
        foregroundColor: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        isBold: Bool = false,
        isUnderlined: Bool = false,
        isDimmed: Bool = false,
        isReversed: Bool = false,
        border: Border? = nil
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.isBold = isBold
        self.isUnderlined = isUnderlined
        self.isDimmed = isDimmed
        self.isReversed = isReversed
        self.border = border
    }
}

public extension TableRowStyle {
    static func focused(
        accent: ANSIColor = .cyan,
        border: Border = Border(leading: "▌ ", trailing: " ▐")
    ) -> TableRowStyle {
        TableRowStyle(
            foregroundColor: accent,
            isBold: true,
            border: border
        )
    }

    static func stripe(
        foregroundColor: ANSIColor? = nil,
        backgroundColor: ANSIColor? = .brightBlack,
        isBold: Bool = false
    ) -> TableRowStyle {
        TableRowStyle(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            isBold: isBold
        )
    }

    static func stripedRows<Row>(
        evenStyle: TableRowStyle? = TableRowStyle.stripe(),
        oddStyle: TableRowStyle? = nil
    ) -> (Row, Int) -> TableRowStyle? {
        { _, index in
            if index.isMultiple(of: 2) {
                return evenStyle
            } else {
                return oddStyle
            }
        }
    }
}

public enum TableDividerStyle {
    case none
    case line(
        character: Character = "─",
        color: ANSIColor? = nil,
        backgroundColor: ANSIColor? = nil,
        isBold: Bool = false
    )
    case custom((Int) -> String)
}

@resultBuilder
public struct TableColumnBuilder<Row> {
    public static func buildBlock(_ components: TableColumn<Row>...) -> [TableColumn<Row>] {
        components
    }

    public static func buildOptional(_ component: [TableColumn<Row>]? ) -> [TableColumn<Row>] {
        component ?? []
    }

    public static func buildEither(first component: [TableColumn<Row>]) -> [TableColumn<Row>] {
        component
    }

    public static func buildEither(second component: [TableColumn<Row>]) -> [TableColumn<Row>] {
        component
    }

    public static func buildArray(_ components: [[TableColumn<Row>]]) -> [TableColumn<Row>] {
        components.flatMap { $0 }
    }
}

public struct Table<Data: RandomAccessCollection, ID: Hashable>: TUIView {
    public typealias Row = Data.Element

    private let data: Data
    private let columns: [TableColumn<Row>]
    private let columnSpacing: Int
    private let rowSpacing: Int
    private let divider: TableDividerStyle
    private let headerBuilder: () -> [any TUIView]
    private let footerBuilder: () -> [any TUIView]
    private let rowStyle: ((Row, Int) -> TableRowStyle?)?
    private let idResolver: (Row) -> ID

    public init(
        _ data: Data,
        id: KeyPath<Row, ID>,
        columnSpacing: Int = 2,
        rowSpacing: Int = 0,
        divider: TableDividerStyle = .none,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>],
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder footer: @escaping () -> [any TUIView] = { [] },
        rowStyle: ((Row, Int) -> TableRowStyle?)? = nil
    ) {
        self.init(
            data,
            id: { $0[keyPath: id] },
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            divider: divider,
            columns: columns,
            header: header,
            footer: footer,
            rowStyle: rowStyle
        )
    }

    public init(
        _ data: Data,
        id: @escaping (Row) -> ID,
        columnSpacing: Int = 2,
        rowSpacing: Int = 0,
        divider: TableDividerStyle = .none,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>],
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder footer: @escaping () -> [any TUIView] = { [] },
        rowStyle: ((Row, Int) -> TableRowStyle?)? = nil
    ) {
        self.data = data
        self.columns = columns()
        self.columnSpacing = max(0, columnSpacing)
        self.rowSpacing = max(0, rowSpacing)
        self.divider = divider
        self.headerBuilder = header
        self.footerBuilder = footer
        self.rowStyle = rowStyle
        self.idResolver = id
    }

    public var body: some TUIView { self }

    public func render() -> String {
        guard !columns.isEmpty else {
            let headerLines = renderViews(headerBuilder())
            let footerLines = renderViews(footerBuilder())
            return (headerLines + footerLines).joined(separator: "\n")
        }

        let renderedHeaderCells = columns.map { column -> RenderedCell in
            RenderedCell(lines: renderViews(column.headerBuilder()))
        }

        var renderedRows: [RenderedRow] = []
        renderedRows.reserveCapacity(data.count)

        var measuredWidths = renderedHeaderCells.map(\.visibleWidth)

        for (index, element) in data.enumerated() {
            _ = idResolver(element)
            var rowCells: [RenderedCell] = []
            rowCells.reserveCapacity(columns.count)
            for column in columns {
                let cell = RenderedCell(lines: renderViews(column.cellBuilder(element)))
                measuredWidths[rowCells.count] = max(measuredWidths[rowCells.count], cell.visibleWidth)
                rowCells.append(cell)
            }
            let style = rowStyle?(element, index)
            renderedRows.append(RenderedRow(cells: rowCells, style: style))
        }

        let resolvedWidths = zip(columns, measuredWidths).map { column, measured in
            Self.resolveWidth(measured: measured, rule: column.width)
        }

        let headerLines = renderHeader(
            renderedCells: renderedHeaderCells,
            columnWidths: resolvedWidths
        )
        let bodyLines = renderBody(
            rows: renderedRows,
            columnWidths: resolvedWidths
        )

        var tableLines: [String] = []
        if let headerLines, !headerLines.isEmpty {
            tableLines.append(contentsOf: headerLines)
            if let dividerLine = makeDividerLine(totalWidth: totalWidth(using: resolvedWidths)) {
                tableLines.append(dividerLine)
            }
        }

        tableLines.append(contentsOf: bodyLines)

        let headerBlock = renderViews(headerBuilder())
        let footerBlock = renderViews(footerBuilder())

        var lines: [String] = []
        lines.reserveCapacity(
            headerBlock.count + tableLines.count + footerBlock.count
        )
        lines.append(contentsOf: headerBlock)
        lines.append(contentsOf: tableLines)
        lines.append(contentsOf: footerBlock)
        return lines.joined(separator: "\n")
    }

    private func renderHeader(
        renderedCells: [RenderedCell],
        columnWidths: [Int]
    ) -> [String]? {
        guard renderedCells.contains(where: { !$0.lines.isEmpty }) else {
            return nil
        }
        return renderRow(cells: renderedCells, columnWidths: columnWidths, style: nil)
    }

    private func renderBody(
        rows: [RenderedRow],
        columnWidths: [Int]
    ) -> [String] {
        guard !rows.isEmpty else { return [] }
        var lines: [String] = []
        lines.reserveCapacity(rows.count * (columnWidths.count + rowSpacing + 1))
        for (index, row) in rows.enumerated() {
            lines.append(contentsOf: renderRow(cells: row.cells, columnWidths: columnWidths, style: row.style))
            if rowSpacing > 0 && index < rows.count - 1 {
                for _ in 0..<rowSpacing {
                    lines.append("")
                }
            }
        }
        return lines
    }

    private func renderRow(
        cells: [RenderedCell],
        columnWidths: [Int],
        style: TableRowStyle?
    ) -> [String] {
        let spacingString = String(repeating: " ", count: columnSpacing)
        let rowHeight = cells.map { $0.lines.count }.max() ?? 0
        guard rowHeight > 0 else { return [] }

        var renderedLines: [String] = []
        renderedLines.reserveCapacity(rowHeight)

        for lineIndex in 0..<rowHeight {
            var pieces: [String] = []
            pieces.reserveCapacity(cells.count)
            for (columnIndex, cell) in cells.enumerated() {
                let line = lineIndex < cell.lines.count ? cell.lines[lineIndex] : ""
                let padded = Self.pad(
                    line,
                    to: columnWidths[columnIndex],
                    alignment: columns[columnIndex].alignment
                )
                pieces.append(padded)
            }
            let rowString = pieces.joined(separator: spacingString)
            renderedLines.append(apply(style: style, to: rowString))
        }

        return renderedLines
    }

    private func makeDividerLine(totalWidth: Int) -> String? {
        guard totalWidth > 0 else { return nil }
        switch divider {
        case .none:
            return nil
        case .line(let character, let color, let background, let isBold):
            let base = String(repeating: String(character), count: totalWidth)
            var prefix = ""
            if let color {
                prefix += color.rawValue
            }
            if let background {
                prefix += background.backgroundCode
            }
            if isBold {
                prefix += "\u{001B}[1m"
            }
            guard !prefix.isEmpty else { return base }
            return prefix + base + ANSIColor.reset.rawValue
        case .custom(let builder):
            return builder(totalWidth)
        }
    }

    private func totalWidth(using columnWidths: [Int]) -> Int {
        let spacingWidth = columnSpacing * max(columnWidths.count - 1, 0)
        return columnWidths.reduce(0, +) + spacingWidth
    }

    private func apply(style: TableRowStyle?, to line: String) -> String {
        guard let style else { return line }

        var decoratedLine = line
        if let border = style.border {
            decoratedLine = border.leading + decoratedLine + border.trailing
        }

        var prefix = ""
        if let fg = style.foregroundColor {
            prefix += fg.rawValue
        }
        if let bg = style.backgroundColor {
            prefix += bg.backgroundCode
        }
        if style.isBold {
            prefix += "\u{001B}[1m"
        }
        if style.isUnderlined {
            prefix += "\u{001B}[4m"
        }
        if style.isDimmed {
            prefix += "\u{001B}[2m"
        }
        if style.isReversed {
            prefix += "\u{001B}[7m"
        }
        guard !prefix.isEmpty else { return decoratedLine }
        return prefix + decoratedLine + ANSIColor.reset.rawValue
    }

    private func renderViews(_ views: [any TUIView]) -> [String] {
        guard !views.isEmpty else { return [] }
        let joined = views.map { $0.render() }.joined(separator: "\n")
        guard !joined.isEmpty else { return [] }
        return joined.splitLinesPreservingEmpty()
    }

    private static func resolveWidth(measured: Int, rule: TableColumn<Row>.Width) -> Int {
        switch rule {
        case .fixed(let value):
            return Swift.max(measured, Swift.max(0, value))
        case .fitContent:
            return measured
        case .flex(let min, let upper):
            var resolved = Swift.max(measured, min)
            if let upper {
                resolved = Swift.min(resolved, upper)
                resolved = Swift.max(resolved, measured)
            }
            return resolved
        }
    }

    private static func pad(
        _ line: String,
        to width: Int,
        alignment: TableColumn<Row>.Alignment
    ) -> String {
        let visibleWidth = HStack.visibleWidth(of: line)
        guard visibleWidth < width else { return line }
        let padding = width - visibleWidth
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

    private struct RenderedCell {
        let lines: [String]

        var visibleWidth: Int {
            lines.map { HStack.visibleWidth(of: $0) }.max() ?? 0
        }
    }

    private struct RenderedRow {
        let cells: [RenderedCell]
        let style: TableRowStyle?
    }
}

public extension Table where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        _ data: Data,
        columnSpacing: Int = 2,
        rowSpacing: Int = 0,
        divider: TableDividerStyle = .none,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>],
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder footer: @escaping () -> [any TUIView] = { [] },
        rowStyle: ((Row, Int) -> TableRowStyle?)? = nil
    ) {
        self.init(
            data,
            id: { $0.id },
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            divider: divider,
            columns: columns,
            header: header,
            footer: footer,
            rowStyle: rowStyle
        )
    }
}
