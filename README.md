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
@main
struct CounterApp: TUIApp {
    var body: some TUIScene {
        CounterScene()
    }
}

struct CounterScene: TUIScene {
    typealias Model = CounterModel
    typealias Action = CounterModel.Action

    var model: CounterModel

    init(model: CounterModel = CounterModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: CounterModel) -> some TUIView {
        CounterView(state: model.state)
    }
}

struct CounterModel {
    enum Action { case increment, decrement }

    @State private var state: CounterState

    init(state: CounterState = CounterState()) {
        self._state = State(wrappedValue: state)
    }

    mutating func update(action: Action) {
        switch action {
        case .increment: state.count += 1
        case .decrement: state.count -= 1
        }
    }
}
```

Tests (or previews) can now inject preconfigured scenes via `CounterScene(model: CounterModel(state: previewState))`.
Written in Swift.

### Text Input & Focus

- Use `@State` for local data and pass `$property` to `TextField`/`TextEditor`. These views now mirror SwiftUI naming: call `.foregroundColor(_)`, `.bold()`, `.focused(_:)`, `.blinkingCursor()`, and `.focusRingStyle(_)` to customise appearance and focus behaviour.
- Declare `@FocusState` for whichever enum identifies focusable elements. `$focused.isFocused(.tag)` returns a `Binding<Bool>` that plugs straight into `.focused(_:)`, while `$focused.moveForward(in:)` / `.moveBackward(in:)` walk a `FocusRing`.
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
- `swift run SwifTeaTaskRunnerExample` simulates a task queue, showcasing the spinner view inline and in the status bar for live progress feedback.

### Layout Primitives

- `VStack` and `HStack` accept `spacing` and alignment arguments that mirror SwiftUI. Need a fixed height? Call `.frame(height:alignment:)` on the stack rather than passing a custom parameter.
- Call `.padding(_:)` on any view to inset the rendered output with ANSI-aware spacing.
- `HStack(spacing:horizontalAlignment:verticalAlignment:)` measures ANSI widths accurately so mixed-color content still lines up.
- All `TUIView` conformers expose `var body: some TUIView`; return `VStack`/`HStack` (or any other view) and the runtime calls `render()` for you—no manual `.render()` needed.

### SwiftUI Parity Notes

- Builders: `@TUIBuilder` now supports `if`/`if let`/`switch`/loops via `buildOptional`, `buildEither`, and `buildArray`, plus a `ForEach(data,id:)` view for data-driven repetition just like `@ViewBuilder`.
- Text: `Text.foregroundColor(_:)` and `Text.bold()` match SwiftUI naming; the old `.foreground`/`.bolded()` methods remain as deprecated shims.
- Inputs: `TextEditor` is the multiline field (with `typealias TextArea` for back-compat). Both `TextField` and `TextEditor` support `.focused(_:)`, `.focusRingStyle(_:)`, `.foregroundColor(_:)`, and `.blinkingCursor()`.
- Focus: `.focused(_:)` mirrors SwiftUI’s modifier, while focus ring visuals come from `.focusRingStyle(_:)` and `FocusRingBorder`.

### Feedback Widgets

- `Spinner` renders an animated activity indicator that follows the runtime clock—use it inline with other views or embed its output inside components like `StatusBar` when background work is in flight. Built-in styles include `.ascii`, `.braille`, `.dots`, and `.line`; prefer `.ascii` or `.dots` when targeting monochrome terminals so glyphs stay legible without color cues.
- `ProgressMeter` draws lightweight `[########----] 75%` bars sized for status strips, making it easy to surface coarse task progress without leaving the status area.
- TaskRunner demonstrates a tiny status message queue so transient updates (step started/completed) cycle through the status bar instead of scrolling the primary layout—handy for longer running Swiftly workflows.
