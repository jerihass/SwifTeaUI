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

public extension TableColumn {
    init<Value>(
        _ title: String? = nil,
        value keyPath: KeyPath<Row, Value>,
        width: Width = .fitContent,
        alignment: Alignment = .leading,
        format: @escaping (Value) -> String = { value in
            String(describing: value)
        }
    ) {
        self.init(
            title,
            width: width,
            alignment: alignment
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

public extension TableRowStyle {
    func merging(_ style: TableRowStyle) -> TableRowStyle {
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

    static func focused(
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
    static func focusedWithMarkers(
        accent: ANSIColor = .cyan,
        border: Border = Border(leading: "▌ ", trailing: " ▐", reserveSpace: true)
    ) -> TableRowStyle {
        focused(accent: accent, border: border)
    }

    static func selected(
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
        guard !columns.isEmpty else {
            let headerLines = renderViews(headerBuilder())
            let footerLines = renderViews(footerBuilder())
            return (headerLines + footerLines).joined(separator: "\n")
        }

        let renderedHeaderCells = columns.map { column -> RenderedCell in
            RenderedCell(rendered: RenderedView(lines: renderViews(column.headerBuilder())))
        }

        var renderedRows: [RenderedRow] = []
        renderedRows.reserveCapacity(data.count)

        var measuredWidths = renderedHeaderCells.map(\.maxWidth)

        for (index, element) in data.enumerated() {
            let id = idResolver(element)
            var rowCells: [RenderedCell] = []
            rowCells.reserveCapacity(columns.count)
            for column in columns {
                let cell = RenderedCell(rendered: RenderedView(lines: renderViews(column.cellBuilder(element))))
                measuredWidths[rowCells.count] = max(measuredWidths[rowCells.count], cell.maxWidth)
                rowCells.append(cell)
            }
            let style = rowStyle?(element, index)
            renderedRows.append(RenderedRow(id: id, cells: rowCells, style: style))
        }

        let resolvedWidths = zip(columns, measuredWidths).map { column, measured in
            Self.resolveWidth(measured: measured, rule: column.width)
        }

        // Resolve styles so we can compute shared gutter reservations.
        let resolvedRows: [ResolvedRow] = renderedRows.map { row in
            ResolvedRow(row: row, style: resolvedStyle(for: row))
        }
        let reservedLeading = resolvedRows.map { $0.gutterLeading }.max() ?? 0
        let reservedTrailing = resolvedRows.map { $0.gutterTrailing }.max() ?? 0
        let rowWidth = totalWidth(using: resolvedWidths) + reservedLeading + reservedTrailing

        let headerLines = renderHeader(
            renderedCells: renderedHeaderCells,
            columnWidths: resolvedWidths,
            reservedLeading: reservedLeading,
            reservedTrailing: reservedTrailing,
            rowWidth: rowWidth
        )
        let bodyLines = renderBody(
            rows: resolvedRows,
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
            columnWidths: columnWidths,
            style: nil,
            reservedLeading: reservedLeading,
            reservedTrailing: reservedTrailing,
            rowWidth: rowWidth
        )
    }

    private func renderBody(
        rows: [ResolvedRow],
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
                let padded = Self.pad(
                    line,
                    currentWidth: cell.width(at: lineIndex),
                    to: columnWidths[columnIndex],
                    alignment: columns[columnIndex].alignment
                )
                pieces.append(padded)
            }
            let rowString = pieces.joined(separator: spacingString)
            renderedLines.append(apply(
                style: style,
                to: rowString,
                totalWidth: rowWidth,
                reservedLeading: reservedLeading,
                reservedTrailing: reservedTrailing
            ))
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

    private func apply(
        style: TableRowStyle?,
        to line: String,
        totalWidth: Int,
        reservedLeading: Int,
        reservedTrailing: Int
    ) -> String {
        let guttered = addGutters(to: line, reservedLeading: reservedLeading, reservedTrailing: reservedTrailing)

        guard let style else { return enforceVisibleWidth(guttered, width: totalWidth) }

        var decoratedLine = guttered
        if let border = style.border {
            let targetLine = border.reserveSpace ? line : guttered
            decoratedLine = overlayBorder(
                targetLine,
                border: border,
                width: totalWidth,
                reservedLeading: reservedLeading,
                reservedTrailing: reservedTrailing
            )
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
        if !prefix.isEmpty {
            decoratedLine = prefix + decoratedLine + ANSIColor.reset.rawValue
        }

        return enforceVisibleWidth(decoratedLine, width: totalWidth)
    }

    private func renderViews(_ views: [any TUIView]) -> [String] {
        guard !views.isEmpty else { return [] }
        let rendered = views.map { resolveRenderedView(for: $0) }
        return rendered.flatMap { $0.lines }
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

        func width(at line: Int) -> Int {
            if line >= 0 && line < rendered.widths.count {
                return rendered.widths[line]
            }
            return -1
        }
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
            guard let border = style?.border, border.reserveSpace else { return 0 }
            return HStack.visibleWidth(of: border.leading)
        }

        var gutterTrailing: Int {
            guard let border = style?.border, border.reserveSpace else { return 0 }
            return HStack.visibleWidth(of: border.trailing)
        }
    }

    private func overlayBorder(
        _ line: String,
        border: TableRowStyle.Border,
        width: Int,
        reservedLeading: Int,
        reservedTrailing: Int
    ) -> String {
        guard width > 0 else { return line }
        let leadingWidth = HStack.visibleWidth(of: border.leading)
        let trailingWidth = HStack.visibleWidth(of: border.trailing)

        // Reserve gutters when requested to avoid covering content.
        if border.reserveSpace {
            let contentWidth = max(0, width - reservedLeading - reservedTrailing)
            let content = enforceVisibleWidth(line, width: contentWidth)
            let leading = padBorderSegment(border.leading, to: reservedLeading)
            let trailing = padBorderSegment(border.trailing, to: reservedTrailing)
            return leading + content + trailing
        }

        var result = line
        if leadingWidth > 0 {
            result = border.leading + dropLeadingVisibleColumns(from: result, count: leadingWidth)
        }

        if trailingWidth > 0 {
            let keepWidth = max(0, width - trailingWidth)
            result = takeLeadingVisibleColumns(from: result, count: keepWidth) + border.trailing
        }

        return enforceVisibleWidth(result, width: width)
    }

    private func enforceVisibleWidth(_ line: String, width: Int) -> String {
        guard width > 0 else { return "" }

        let currentWidth = HStack.visibleWidth(of: line)
        if currentWidth == width {
            return line
        } else if currentWidth < width {
            return line + String(repeating: " ", count: width - currentWidth)
        }

        // Trim to the requested width while preserving ANSI sequences.
        var visibleIndex = 0
        var produced = 0
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
                    // keep sequences even if we don't emit visible chars yet
                    if produced < width {
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
                if produced < width {
                    if !pendingSequences.isEmpty {
                        result.append(pendingSequences)
                        pendingSequences.removeAll(keepingCapacity: true)
                    }
                    result.append(character)
                    produced += 1
                }
                visibleIndex += 1
                if produced >= width && !inEscape {
                    // discard remaining visible characters
                    // but continue consuming escapes to keep index advancing
                }
            }
            index = line.index(after: index)
            if produced >= width && !inEscape {
                // We can break early once we hit the width and not inside escape.
                break
            }
        }

        if !result.hasSuffix(ANSIColor.reset.rawValue) {
            result += ANSIColor.reset.rawValue
        }
        return result
    }

    private func addGutters(to line: String, reservedLeading: Int, reservedTrailing: Int) -> String {
        let leading = reservedLeading > 0 ? String(repeating: " ", count: reservedLeading) : ""
        let trailing = reservedTrailing > 0 ? String(repeating: " ", count: reservedTrailing) : ""
        return leading + line + trailing
    }

    private func padBorderSegment(_ segment: String, to width: Int) -> String {
        guard width > 0 else { return "" }
        let current = HStack.visibleWidth(of: segment)
        if current == width { return segment }
        if current < width {
            return segment + String(repeating: " ", count: width - current)
        }
        return takeLeadingVisibleColumns(from: segment, count: width)
    }

    private func dropLeadingVisibleColumns(from line: String, count: Int) -> String {
        guard count > 0 else { return line }

        var visibleIndex = 0
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
                if visibleIndex >= count {
                    if !capturing {
                        capturing = true
                        if !pendingSequences.isEmpty {
                            result.append(pendingSequences)
                            pendingSequences.removeAll(keepingCapacity: true)
                        }
                    }
                    result.append(character)
                }
                visibleIndex += 1
            }
            index = line.index(after: index)
        }

        return capturing ? result : ""
    }

    private func takeLeadingVisibleColumns(from line: String, count: Int) -> String {
        guard count > 0 else { return "" }

        var visibleIndex = 0
        var produced = 0
        var result = ""
        var index = line.startIndex
        var inEscape = false
        var currentSequence = ""

        while index < line.endIndex {
            let character = line[index]
            if inEscape {
                currentSequence.append(character)
                if character.isANSISequenceTerminator {
                    inEscape = false
                    result.append(currentSequence)
                    currentSequence.removeAll(keepingCapacity: true)
                }
            } else if character == "\u{001B}" {
                inEscape = true
                currentSequence = "\u{001B}"
            } else {
                if produced < count {
                    result.append(character)
                    produced += 1
                } else {
                    break
                }
                visibleIndex += 1
            }
            index = line.index(after: index)
        }

        if produced < count {
            result += String(repeating: " ", count: count - produced)
        }
        return result
    }
}

public extension Table where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        _ data: Data,
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
