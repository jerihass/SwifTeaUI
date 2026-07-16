import Foundation

public enum TableLayout: Sendable, Equatable {
    case intrinsic
    case fitProposal
}

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

    public enum Visibility: Sendable, Equatable {
        case always
        case whenSpaceAllows(priority: Int = 0)
    }

    public enum Overflow: Sendable, Equatable {
        case visible
        case clip
        case ellipsis
    }

    let width: Width
    let alignment: Alignment
    let visibility: Visibility
    let overflow: Overflow
    let layoutPriority: Int
    let headerBuilder: () -> [any TUIView]
    let cellBuilder: (Row) -> [any TUIView]

    public init(
        _ title: String? = nil,
        width: Width = .fitContent,
        alignment: Alignment = .leading,
        visibility: Visibility = .always,
        overflow: Overflow = .visible,
        layoutPriority: Int = 0,
        @TUIBuilder _ content: @escaping (Row) -> [any TUIView]
    ) {
        self.init(
            width: width,
            alignment: alignment,
            visibility: visibility,
            overflow: overflow,
            layoutPriority: layoutPriority,
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
        visibility: Visibility = .always,
        overflow: Overflow = .visible,
        layoutPriority: Int = 0,
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder _ content: @escaping (Row) -> [any TUIView]
    ) {
        self.width = width
        self.alignment = alignment
        self.visibility = visibility
        self.overflow = overflow
        self.layoutPriority = layoutPriority
        self.headerBuilder = header
        self.cellBuilder = content
    }
}

extension TableColumn {
    public init<Value>(
        _ title: String? = nil,
        value keyPath: KeyPath<Row, Value>,
        width: Width = .fitContent,
        alignment: Alignment = .leading,
        visibility: Visibility = .always,
        overflow: Overflow = .visible,
        layoutPriority: Int = 0,
        format: @escaping (Value) -> String = { value in
            String(describing: value)
        }
    ) {
        self.init(
            title,
            width: width,
            alignment: alignment,
            visibility: visibility,
            overflow: overflow,
            layoutPriority: layoutPriority
        ) { row in
            Text(format(row[keyPath: keyPath]))
        }
    }
}

public struct TableRowStyle {
    public struct Border {
        public var leading: String
        public var trailing: String
        public var reserveSpace: Bool

        public init(leading: String = "│ ", trailing: String = " │", reserveSpace: Bool = false) {
            self.leading = leading
            self.trailing = trailing
            self.reserveSpace = reserveSpace
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

extension TableRowStyle {
    public func merging(_ style: TableRowStyle) -> TableRowStyle {
        TableRowStyle(
            foregroundColor: style.foregroundColor ?? self.foregroundColor,
            backgroundColor: style.backgroundColor ?? self.backgroundColor,
            isBold: self.isBold || style.isBold,
            isUnderlined: self.isUnderlined || style.isUnderlined,
            isDimmed: self.isDimmed || style.isDimmed,
            isReversed: self.isReversed || style.isReversed,
            border: style.border ?? self.border
        )
    }

    public static func focused(
        accent: ANSIColor = .cyan,
        border: Border? = Border(leading: "▌ ", trailing: " ▐", reserveSpace: true)
    ) -> TableRowStyle {
        TableRowStyle(
            foregroundColor: accent,
            isBold: true,
            border: border
        )
    }

    /// Focused style with explicit gutter markers that reserve space so content remains aligned.
    public static func focusedWithMarkers(
        accent: ANSIColor = .cyan,
        border: Border = Border(leading: "▌ ", trailing: " ▐", reserveSpace: true)
    ) -> TableRowStyle {
        focused(accent: accent, border: border)
    }

    public static func selected(
        foregroundColor: ANSIColor? = nil,
        backgroundColor: ANSIColor = .blue,
        isBold: Bool = true,
        border: Border? = nil
    ) -> TableRowStyle {
        TableRowStyle(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            isBold: isBold,
            border: border
        )
    }

    public static func stripe(
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

    public static func stripedRows<Row>(
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

    public static func buildOptional(_ component: [TableColumn<Row>]?) -> [TableColumn<Row>] {
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

public struct TableSelectionConfiguration<ID: Hashable> {
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
    ) -> TableSelectionConfiguration<ID> {
        TableSelectionConfiguration(
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
    ) -> TableSelectionConfiguration<ID> {
        TableSelectionConfiguration(
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

public struct Table<Data: RandomAccessCollection, ID: Hashable>: TUIView {
    public typealias Row = Data.Element

    private let data: Data
    private let columns: [TableColumn<Row>]
    private let layout: TableLayout
    private let columnSpacing: Int
    private let rowSpacing: Int
    private let divider: TableDividerStyle
    private let headerBuilder: () -> [any TUIView]
    private let footerBuilder: () -> [any TUIView]
    private let rowStyle: ((Row, Int) -> TableRowStyle?)?
    private let selectionConfiguration: TableSelectionConfiguration<ID>?
    private let idResolver: (Row) -> ID

    public init(
        _ data: Data,
        id: KeyPath<Row, ID>,
        layout: TableLayout = .intrinsic,
        columnSpacing: Int = 2,
        rowSpacing: Int = 0,
        divider: TableDividerStyle = .none,
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder footer: @escaping () -> [any TUIView] = { [] },
        selection: TableSelectionConfiguration<ID>? = nil,
        rowStyle: ((Row, Int) -> TableRowStyle?)? = nil,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(
            data,
            id: { $0[keyPath: id] },
            layout: layout,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            divider: divider,
            header: header,
            footer: footer,
            selection: selection,
            rowStyle: rowStyle,
            columns: columns
        )
    }

    public init(
        _ data: Data,
        id: @escaping (Row) -> ID,
        layout: TableLayout = .intrinsic,
        columnSpacing: Int = 2,
        rowSpacing: Int = 0,
        divider: TableDividerStyle = .none,
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder footer: @escaping () -> [any TUIView] = { [] },
        selection: TableSelectionConfiguration<ID>? = nil,
        rowStyle: ((Row, Int) -> TableRowStyle?)? = nil,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.data = data
        self.layout = layout
        self.columnSpacing = max(0, columnSpacing)
        self.rowSpacing = max(0, rowSpacing)
        self.divider = divider
        self.headerBuilder = header
        self.footerBuilder = footer
        self.rowStyle = rowStyle
        self.selectionConfiguration = selection
        self.idResolver = id
        self.columns = columns()
    }

    public var body: some TUIView { self }

    public func render() -> String {
        render(in: RenderEnvironment.current)
    }

    public func render(in context: RenderContext) -> String {
        guard !columns.isEmpty else {
            let headerLines = renderViews(headerBuilder(), in: context)
            let footerLines = renderViews(footerBuilder(), in: context)
            return (headerLines + footerLines).joined(separator: "\n")
        }

        let allHeaderCells = columns.map { column -> RenderedCell in
            RenderedCell(rendered: RenderedView(lines: renderViews(column.headerBuilder(), in: .unspecified)))
        }

        var allRows: [RenderedRow] = []
        allRows.reserveCapacity(data.count)

        var measuredWidths = allHeaderCells.map(\.maxWidth)

        for (index, element) in data.enumerated() {
            let id = idResolver(element)
            var rowCells: [RenderedCell] = []
            rowCells.reserveCapacity(columns.count)
            for column in columns {
                let cell = RenderedCell(
                    rendered: RenderedView(
                        lines: renderViews(column.cellBuilder(element), in: .unspecified)
                    )
                )
                measuredWidths[rowCells.count] = max(measuredWidths[rowCells.count], cell.maxWidth)
                rowCells.append(cell)
            }
            let style = rowStyle?(element, index)
            allRows.append(RenderedRow(id: id, cells: rowCells, style: style))
        }

        let styledRows: [ResolvedRow] = allRows.map { row in
            ResolvedRow(row: row, style: resolvedStyle(for: row))
        }
        let reservedLeading = styledRows.map { $0.gutterLeading }.max() ?? 0
        let reservedTrailing = styledRows.map { $0.gutterTrailing }.max() ?? 0
        let columnBudget = context.proposedSize.width.map {
            max(0, $0 - reservedLeading - reservedTrailing)
        }
        let resolution = resolveColumns(measuredWidths: measuredWidths, budget: columnBudget)
        let activeColumns = resolution.indices.map { columns[$0] }
        let renderedHeaderCells = resolution.indices.map { allHeaderCells[$0] }
        let resolvedRows = styledRows.map { resolved in
            ResolvedRow(
                row: RenderedRow(
                    id: resolved.row.id,
                    cells: resolution.indices.map { resolved.row.cells[$0] },
                    style: resolved.row.style
                ),
                style: resolved.style
            )
        }
        let resolvedWidths = resolution.widths
        let rowWidth = totalWidth(using: resolvedWidths) + reservedLeading + reservedTrailing

        let headerLines = renderHeader(
            renderedCells: renderedHeaderCells,
            columns: activeColumns,
            columnWidths: resolvedWidths,
            reservedLeading: reservedLeading,
            reservedTrailing: reservedTrailing,
            rowWidth: rowWidth
        )
        let bodyLines = renderBody(
            rows: resolvedRows,
            columns: activeColumns,
            columnWidths: resolvedWidths,
            reservedLeading: reservedLeading,
            reservedTrailing: reservedTrailing,
            rowWidth: rowWidth
        )

        var tableLines: [String] = []
        if let headerLines, !headerLines.isEmpty {
            tableLines.append(contentsOf: headerLines)
            if let dividerLine = makeDividerLine(totalWidth: totalWidth(using: resolvedWidths)) {
                tableLines.append(dividerLine)
            }
        }

        tableLines.append(contentsOf: bodyLines)

        let headerBlock = renderViews(headerBuilder(), in: context)
        let footerBlock = renderViews(footerBuilder(), in: context)

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
        columns: [TableColumn<Row>],
        columnWidths: [Int],
        reservedLeading: Int,
        reservedTrailing: Int,
        rowWidth: Int
    ) -> [String]? {
        guard renderedCells.contains(where: { !$0.lines.isEmpty }) else {
            return nil
        }
        return renderRow(
            cells: renderedCells,
            columns: columns,
            columnWidths: columnWidths,
            style: nil,
            reservedLeading: reservedLeading,
            reservedTrailing: reservedTrailing,
            rowWidth: rowWidth
        )
    }

    private func renderBody(
        rows: [ResolvedRow],
        columns: [TableColumn<Row>],
        columnWidths: [Int],
        reservedLeading: Int,
        reservedTrailing: Int,
        rowWidth: Int
    ) -> [String] {
        guard !rows.isEmpty else { return [] }
        var lines: [String] = []
        lines.reserveCapacity(rows.count * (columnWidths.count + rowSpacing + 1))
        for (index, row) in rows.enumerated() {
            lines.append(
                contentsOf: renderRow(
                    cells: row.row.cells,
                    columns: columns,
                    columnWidths: columnWidths,
                    style: row.style,
                    reservedLeading: reservedLeading,
                    reservedTrailing: reservedTrailing,
                    rowWidth: rowWidth
                )
            )
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
        columns: [TableColumn<Row>],
        columnWidths: [Int],
        style: TableRowStyle?,
        reservedLeading: Int,
        reservedTrailing: Int,
        rowWidth: Int
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
                let fitted = fit(
                    line,
                    to: columnWidths[columnIndex],
                    overflow: columns[columnIndex].overflow
                )
                let padded = Self.pad(
                    fitted,
                    currentWidth: TerminalText.visibleWidth(of: fitted),
                    to: columnWidths[columnIndex],
                    alignment: columns[columnIndex].alignment
                )
                pieces.append(padded)
            }
            let rowString = pieces.joined(separator: spacingString)
            renderedLines.append(
                RowStyleRenderer.apply(
                    style: style,
                    to: rowString,
                    totalWidth: rowWidth,
                    reservedLeading: reservedLeading,
                    reservedTrailing: reservedTrailing
                )
            )
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

    private func renderViews(
        _ views: [any TUIView],
        in context: RenderContext = RenderEnvironment.current
    ) -> [String] {
        guard !views.isEmpty else { return [] }
        let rendered = views.map { resolveRenderedView(for: $0, in: context) }
        return rendered.flatMap { $0.lines }
    }

    private func resolveColumns(measuredWidths: [Int], budget: Int?) -> ColumnResolution {
        guard layout == .fitProposal, let budget else {
            return ColumnResolution(
                indices: Array(columns.indices),
                widths: zip(measuredWidths, columns).map {
                    Self.resolveWidth(measured: $0.0, rule: $0.1.width)
                }
            )
        }

        var activeIndices = Array(columns.indices)
        let optionalIndices =
            activeIndices
            .compactMap { index -> (index: Int, priority: Int)? in
                guard case .whenSpaceAllows(let priority) = columns[index].visibility else {
                    return nil
                }
                return (index, priority)
            }
            .sorted {
                if $0.priority == $1.priority {
                    return $0.index > $1.index
                }
                return $0.priority < $1.priority
            }

        for optional in optionalIndices {
            guard minimumTableWidth(for: activeIndices, measuredWidths: measuredWidths) > budget else {
                break
            }
            activeIndices.removeAll { $0 == optional.index }
        }

        let spacing = columnSpacing * max(activeIndices.count - 1, 0)
        let availableContentWidth = max(0, budget - spacing)
        var widths = activeIndices.map { index in
            Self.minimumWidth(for: columns[index], measured: measuredWidths[index])
        }

        var deficit = max(0, widths.reduce(0, +) - availableContentWidth)
        let shrinkOrder = activeIndices.indices.sorted { lhs, rhs in
            let left = columns[activeIndices[lhs]]
            let right = columns[activeIndices[rhs]]
            if left.layoutPriority == right.layoutPriority {
                return lhs > rhs
            }
            return left.layoutPriority < right.layoutPriority
        }
        for position in shrinkOrder where deficit > 0 {
            let column = columns[activeIndices[position]]
            guard column.overflow != .visible else { continue }
            let reduction = min(deficit, max(0, widths[position] - 1))
            widths[position] -= reduction
            deficit -= reduction
        }

        var remaining = max(0, availableContentWidth - widths.reduce(0, +))
        growFlexColumns(
            widths: &widths,
            activeIndices: activeIndices,
            measuredWidths: measuredWidths,
            remaining: &remaining,
            towardPreferredWidth: true
        )
        growFlexColumns(
            widths: &widths,
            activeIndices: activeIndices,
            measuredWidths: measuredWidths,
            remaining: &remaining,
            towardPreferredWidth: false
        )

        return ColumnResolution(indices: activeIndices, widths: widths)
    }

    private func minimumTableWidth(for indices: [Int], measuredWidths: [Int]) -> Int {
        let contentWidth = indices.reduce(into: 0) { result, index in
            result += Self.minimumWidth(for: columns[index], measured: measuredWidths[index])
        }
        return contentWidth + columnSpacing * max(indices.count - 1, 0)
    }

    private func growFlexColumns(
        widths: inout [Int],
        activeIndices: [Int],
        measuredWidths: [Int],
        remaining: inout Int,
        towardPreferredWidth: Bool
    ) {
        guard remaining > 0 else { return }
        let positions = activeIndices.indices
            .filter {
                if case .flex = columns[activeIndices[$0]].width { return true }
                return false
            }
            .sorted {
                let left = columns[activeIndices[$0]].layoutPriority
                let right = columns[activeIndices[$1]].layoutPriority
                if left == right { return $0 < $1 }
                return left > right
            }
        guard !positions.isEmpty else { return }

        var madeProgress = true
        while remaining > 0, madeProgress {
            madeProgress = false
            for position in positions where remaining > 0 {
                let index = activeIndices[position]
                let limit: Int
                if towardPreferredWidth {
                    limit = Self.preferredWidth(for: columns[index], measured: measuredWidths[index])
                } else {
                    limit = Self.maximumWidth(for: columns[index])
                }
                guard widths[position] < limit else { continue }
                widths[position] += 1
                remaining -= 1
                madeProgress = true
            }
        }
    }

    private static func minimumWidth(for column: TableColumn<Row>, measured: Int) -> Int {
        switch column.width {
        case .fixed(let value):
            return max(0, value)
        case .fitContent:
            return measured
        case .flex(let minimum, let maximum):
            return min(max(0, minimum), maximum.map { max(0, $0) } ?? Int.max)
        }
    }

    private static func preferredWidth(for column: TableColumn<Row>, measured: Int) -> Int {
        switch column.width {
        case .fixed(let value):
            return max(0, value)
        case .fitContent:
            return measured
        case .flex(let minimum, let maximum):
            let preferred = max(measured, max(0, minimum))
            return min(preferred, maximum.map { max(0, $0) } ?? Int.max)
        }
    }

    private static func maximumWidth(for column: TableColumn<Row>) -> Int {
        switch column.width {
        case .fixed(let value):
            return max(0, value)
        case .fitContent:
            return Int.max
        case .flex(_, let maximum):
            return maximum.map { max(0, $0) } ?? Int.max
        }
    }

    private func fit(
        _ line: String,
        to width: Int,
        overflow: TableColumn<Row>.Overflow
    ) -> String {
        guard width > 0 else { return "" }
        guard TerminalText.visibleWidth(of: line) > width else { return line }
        switch overflow {
        case .visible:
            return line
        case .clip:
            return TerminalText.fittedLine(line, to: width, padded: false)
        case .ellipsis:
            guard width > 1 else { return "…" }
            let prefix = TerminalText.fittedLine(line, to: width - 1, padded: false)
            let padding = max(0, width - 1 - TerminalText.visibleWidth(of: prefix))
            return prefix + String(repeating: " ", count: padding) + "…"
        }
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
        currentWidth: Int,
        to width: Int,
        alignment: TableColumn<Row>.Alignment
    ) -> String {
        let visibleWidth = currentWidth >= 0 ? currentWidth : HStack.visibleWidth(of: line)
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
        let rendered: RenderedView

        var lines: [String] { rendered.lines }
        var maxWidth: Int { rendered.maxWidth }
    }

    private struct ColumnResolution {
        let indices: [Int]
        let widths: [Int]
    }

    private func resolvedStyle(for row: RenderedRow) -> TableRowStyle? {
        var style = row.style
        if let selectionConfiguration, selectionConfiguration.isSelected(row.id) {
            style = style?.merging(selectionConfiguration.selectionStyle) ?? selectionConfiguration.selectionStyle
        }
        if let selectionConfiguration, selectionConfiguration.isFocused(row.id) {
            style = style?.merging(selectionConfiguration.focusedStyle) ?? selectionConfiguration.focusedStyle
        }
        return style
    }

    private struct RenderedRow {
        let id: ID
        let cells: [RenderedCell]
        let style: TableRowStyle?
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

extension Table where Data.Element: Identifiable, Data.Element.ID == ID {
    public init(
        _ data: Data,
        layout: TableLayout = .intrinsic,
        columnSpacing: Int = 2,
        rowSpacing: Int = 0,
        divider: TableDividerStyle = .none,
        @TUIBuilder header: @escaping () -> [any TUIView] = { [] },
        @TUIBuilder footer: @escaping () -> [any TUIView] = { [] },
        selection: TableSelectionConfiguration<ID>? = nil,
        rowStyle: ((Row, Int) -> TableRowStyle?)? = nil,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(
            data,
            id: { $0.id },
            layout: layout,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            divider: divider,
            header: header,
            footer: footer,
            selection: selection,
            rowStyle: rowStyle,
            columns: columns
        )
    }
}
