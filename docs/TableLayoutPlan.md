# SwifTeaUI Table Layout Plan

## Goals
- Provide a first-class `Table` view so SwifTeaUI apps can render structured data without nesting ad-hoc stacks.
- Follow SwiftUI’s `Table` ergonomics: declare columns once, feed in a collection, and rely on the runtime for sizing/alignment.
- Respect terminal constraints (monospaced grids, ANSI codes, predictable performance) while supporting multi-line cells.

## Proposed API
```swift
struct Process: Identifiable { /* ... */ }

Table(processes, columnSpacing: 2, rowSpacing: 1, divider: .line()) {
    TableColumn("Name", alignment: .leading) { process in
        Text(process.name).bold()
    }
    TableColumn("Duration", width: .fitContent, alignment: .center) { process in
        Text("\(process.duration)s")
    }
    TableColumn("State", width: .fixed(12), alignment: .trailing) { process in
        StatusBadge(state: process.state)
    }
} header: {
    Text("Running Tasks").foregroundColor(.yellow).bold()
} footer: {
    Text("\(processes.count) items").italic()
} rowStyle: { process, index in
    if process.isFocused { return TableRowStyle(foregroundColor: .cyan, isBold: true) }
    if index.isMultiple(of: 2) { return TableRowStyle(backgroundColor: .brightBlack) }
    return nil
}
```

### Already available
- `TableColumn` ships today with optional title text, width strategies (`.fixed`, `.fitContent`, `.flex(min:max:)`), alignment, and builders for header/cells.
- `Table` is implemented with header/footer builders, divider styles via `TableDividerStyle`, configurable row/column spacing, and row styling hooks.
- Overloads exist for `Identifiable` collections (`Table(data)`), and the runtime measures column widths + cell heights eagerly so each frame renders once.

### Future API Enhancements
- Selection binding and keyboard focus helpers so tables can control global focus without extra boilerplate.
- Key-path convenience columns (`TableColumn(value: \.name)`), default striping helpers, and divider themes with ANSI colors.

## Rendering Strategy
1. **Column registration**: Evaluate the column builder once to collect descriptors (header, width rule, alignment, cell closure).
2. **Measurement pass**:
   - Render each cell once, caching the string plus visible width/line count (reuse `HStack.visibleWidth` measurement helpers).
   - Compute per-column widths based on the rendered cells and width strategies; clamp/expand to satisfy `.fixed`, `.fitContent`, and `.flex` rules.
3. **Row rendering**:
   - Render header row (if present), padding each header cell to its column width and joining with configured spacing or separators.
   - Optionally draw a divider (`─` line or custom style) beneath the header.
   - For each data row, pad cells to the column width using alignment rules; multi-line cells expand the row height using `HStack`’s vertical distribution logic.
   - Apply row styles (striped backgrounds, selection emphasis) by wrapping the composed row string with ANSI prefixes/suffixes.
4. **Composition**: Stack header, divider, body rows, and footer inside a `VStack(spacing:)`, exposing `Table` as a standard `TUIView`.

## Implementation Phases
1. **Foundations (Completed)**
   - `TableColumn`, width/alignment enums, and shared measurement helpers live in `Sources/SwifTeaUI/Table.swift`.
   - `HStack.visibleWidth` + padding utilities already power the column measuring logic.
2. **Table Core (Completed)**
   - `Table<Data>` renders header/body/footer blocks, handles dividers, spacing, and caches cell strings per row.
   - Both `id:` closure and `Identifiable` overloads are implemented.
3. **Styling Layer (In Progress)**
   - `TableRowStyle` now handles underline/dim/reverse flags plus optional leading/trailing borders so focused rows can render outlines without custom view wrappers.
   - `TableDividerStyle` exposes colored `.line` dividers and full custom builders; `TableRowStyle.stripedRows` ships as a convenience helper for zebra striping.
4. **Ergonomics & Docs (In Progress)**
   - Example usage is limited to the Package List demo; README/docs still need a dedicated table section.
   - TODO: add key-path column sugar and focus/selection bindings inspired by SwiftUI’s table selection API.

## Testing Plan
- ✅ `Tests/SwifTeaUITests/TableTests.swift` exercises header/footer rendering, divider lines, width rules, and ANSI row styling.
- Planned additions:
  - Multi-line cell alignment + spacing assertions.
  - Snapshot-style fixtures for realistic datasets (task list, package listing) to guard against regressions.
  - Performance sanity tests confirming rendering work scales with `rows × columns` and avoids redundant view construction.

## Adoption Steps
1. ✅ Core `Table` implementation merged (see `Sources/SwifTeaUI/Table.swift`).
2. ✅ Package List example uses the API to validate ergonomics with real data.
3. 🔄 Document the component (README + docs), add another sample (e.g., Task Runner), and iterate on remaining API gaps (selection, key-path helpers).
