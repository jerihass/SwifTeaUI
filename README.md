# SwifTeaUI 🍵

A modern, declarative **Terminal UI framework for Swift**, inspired by SwiftUI and Bubble Tea.

### Goals

✅ SwiftUI-like declarative syntax  
✅ POSIX & ANSI abstractions handled for you  
✅ Async actions, effects, and key event routing  
✅ Cross-platform (macOS + Linux)  
✅ Clean, composable view system

### Example

```swift
struct CounterApp: TUIApp {
    // ...
}
@main struct Main {
    static func main() {
        SwifTea.brew(CounterApp())
    }
}
```
Written in Swift.

### Text Input & Focus

- Use `@State` to back local view data and pass `$property` as a `Binding`. `TextField` accepts that binding plus an optional `Binding<Bool>` controlling focus; it shows the cursor only while focused.
- Declare `@FocusState` for whichever enum identifies focusable elements. `$focused.isFocused(.tag)` returns a `Binding<Bool>` you can hand to focusable views, and `$focused.moveForward(in:)` / `.moveBackward(in:)` will walk a `FocusRing`.
- Wrap related fields in a `FocusScope` so Tab and Shift+Tab navigation can stay inside that group before falling back to a global ring. Terminal Shift+Tab arrives as `.backTab` in `KeyEvent`.
- Typical pattern:
  ```swift
  enum Field: Hashable { case controls, title, body }
  @FocusState private var focused: Field?
  private let globalRing = FocusRing<Field>([.controls, .title, .body])
  private let noteScope = FocusScope<Field>([.title, .body], wraps: false)

  mutating func update(action: Action) {
      switch action {
      case .focusNext:
          if !$focused.moveForward(in: noteScope),
             let next = globalRing.move(from: focused, direction: .forward) {
              focused = next
          }
      case .focusPrevious:
          if !$focused.moveBackward(in: noteScope),
             let prev = globalRing.move(from: focused, direction: .backward) {
              focused = prev
          }
      default:
          break
      }
  }
  ```

### Examples

- `swift run SwifTeaCounterExample` shows the basics: counter controls alongside a focused text field.
- `swift run SwifTeaNotebookExample` demonstrates two panes with scoped focus rings, arrow-key navigation, and text entry across multiple fields.

### Layout Primitives

- `VStack(spacing:alignment:)` stacks views vertically; spacing defaults to `0`, alignment accepts `.leading`, `.center`, or `.trailing` and pads multi-line content accordingly (only non-leading alignments add horizontal padding).
- `HStack(spacing:horizontalAlignment:verticalAlignment:)` arranges columns and measures ANSI-safe widths. Horizontal alignment mirrors `VStack` while vertical alignment supports `.top`, `.center`, and `.bottom` for shorter columns.
- The notebook example centers the header `VStack` and top-aligns the sidebar/editor `HStack` to showcase the options.
