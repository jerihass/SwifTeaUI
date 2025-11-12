# SwifTeaUI Table Layout Plan

## Goals
- Provide a first-class `Table` view so callers such as Mint can render tabular data without manually composing nested stacks.
- Match SwiftUI-inspired ergonomics: declare columns once, feed in a data collection, and let the runtime align cells.
- Preserve SwifTeaUI constraints (ASCII terminals, line-based rendering) while keeping performance predictable.

## Proposed API
```swift
Table(data, id: \.id, spacing: 1, divider: .bordered) {
    TableColumn("Package", width: .flex(min: 18), alignment: .leading) { item in
        Text(item.name).bold()
    }
    TableColumn("Version", width: .fitContent, alignment: .center) { item in
        Text(item.version)
    }
    TableColumn("Status", width: .fixed(14), alignment: .trailing) { item in
        StatusBadge(state: item.state)
    }
} header: {
    Text("Installed Packages").foregroundColor(.yellow).bold()
} footer: {
    Text("\(data.count) total packages").italic()
}
```

- `TableColumn` captures title text (optional), width strategy (`.fixed`, `.fitContent`, `.flex(min:max:)`), alignment, and cell builder.
- `Table` accepts an optional header/footer builder plus per-row modifiers (striping, selection highlight) via a `TableRowStyle`.
- Provide convenience overloads when header/footer are omitted.

## Rendering Strategy
1. **Column registration**: Evaluate the column builder to collect column descriptors (header view, width rule, alignment, cell closure).
2. **Measurement pass**:
   - For every row & column, build the cell views once (reusing `TUIBuilder`) and cache rendered strings.
   - Track visible width (via existing `HStack.visibleWidth(of:)`) and line count per cell to handle multi-line text.
   - Accumulate the max visible width per column; enforce width strategy (fixed overrides, `fitContent` uses max cell width, `flex` takes the larger of min width and fitContent, clamped to max if provided).
3. **Row rendering**:
   - Render header row first (if provided), padding each header cell to column width and joining with a configurable spacing or separator glyph.
   - Optionally render a divider (line of `─` characters) after the header when `.bordered` divider style is used.
   - For each row, pad every cell to its column width respecting column alignment, then join into a single line per visual row (multi-line cells may expand the row height; use the same vertical alignment logic from `HStack` to balance lines).
   - Apply row style hooks (striped background, highlight selection) by wrapping the final text in ANSI codes before joining.
4. **Composition**: Stack header, divider, body rows, footer inside a `VStack(spacing:)`; expose the table as a regular `TUIView` so it nests inside existing layouts.

## Implementation Phases
1. **Foundations**
   - Add `ColumnWidthRule` / `ColumnAlignment` helpers and a `TableColumn` struct under `Sources/SwifTeaUI/Table/`.
   - Implement shared utilities for measuring visible widths and padding strings (can reuse or extend current `HStack` helpers).
2. **Table Core**
   - Create `Table<Data>` view storing data, column descriptors, spacing, divider style, header/footer closures, and optional row style closure.
   - Implement the measurement and rendering passes described above.
3. **Styling Layer**
   - Introduce `TableRowStyle` protocol/struct for zebra-striping, selection highlighting, and status coloring.
   - Support divider styles: `.none`, `.bordered`, `.custom(character:String)`.
4. **Integrations & Ergonomics**
   - Provide `Table` convenience initializers for simple `String` headers, default width rules, and implicit `Identifiable` data.
   - Document how `Table` interacts with `ForEach` (e.g., reusing its diff IDs later).

## Testing Plan
- Unit tests in `Tests/SwifTeaUITests/TableTests.swift` covering:
  - Column width resolution for each rule type.
  - Multi-line cells and alignment (leading, center, trailing).
  - Header/divider rendering and optional footer.
  - Row styling hooks (striped rows, selection emphasis).
- Snapshot tests in `TaskRunnerSnapshotTests`-style fixtures for realistic datasets (Mint packages, task lists) to ensure stability.
- Performance sanity check: verify rendering cost scales linearly with `rows * columns` and avoids redundant view construction per frame.

## Adoption Steps
1. Land `Table` implementation behind feature flag or hidden API.
2. Update Mint’s WIP UI to consume `Table`, ensuring API covers real-world needs (e.g., column reordering, selection highlighting).
3. Iterate based on Mint feedback, then document the component in `README.md` with examples and ASCII screenshots.
