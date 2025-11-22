# SwifTeaUI 🍵

A modern, declarative **Terminal UI framework for Swift**, inspired by SwiftUI and Bubble Tea.

### A Tiny SwifTeaUI App

SwifTeaUI mirrors SwiftUI’s DSL.

```swift
import SwifTeaUI

@main
struct TinyCounterApp: TUIApp {
    var body: some TUIScene { TinyCounterScene() }
}

struct TinyCounterScene: TUIScene {
    typealias Model = TinyCounterModel
    typealias Action = TinyCounterModel.Action

    var model: TinyCounterModel

    init(model: TinyCounterModel = TinyCounterModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: TinyCounterModel) -> some TUIView {
        model.makeView()
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        model.mapKeyToAction(key)
    }

    func shouldExit(for action: Action) -> Bool {
        model.shouldExit(for: action)
    }
}

struct TinyCounterModel {
    enum Action { case increment, decrement, quit }

    @State private var count = 0

    mutating func update(action: Action) {
        switch action {
        case .increment: count += 1
        case .decrement: count -= 1
        case .quit: break
        }
    }

    func makeView() -> some TUIView {
        TinyCounterView(count: count)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .rightArrow, .char("+"): return .increment
        case .leftArrow, .char("-"): return .decrement
        case .char("q"), .escape: return .quit
        default: return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action { return true }
        return false
    }
}

struct TinyCounterView: TUIView {
    let count: Int

    var body: some TUIView {
        Border(
            padding: 1,
            VStack(spacing: 1, alignment: .leading) {
                Text("Tiny Counter").foregroundColor(.yellow).bold()
                Text("Use ←/→ or +/- to change the value, press q to quit.")
                    .foregroundColor(.cyan)
                Text("Count: \(count)").foregroundColor(.green)
            }
        )
        .padding(1)
    }
}
```

The scene maps terminal key events to reducer actions, `@State` keeps the counter value live, and the runtime renders the ANSI layout—no manual escape codes required.

### Goals

✅ SwiftUI-like declarative syntax  
✅ POSIX & ANSI abstractions handled for you  
✅ Async actions, effects, and key event routing  
✅ Cross-platform (macOS + Linux)  
✅ Clean, composable view system

### Async Effects & Dispatch

- Dispatch reducer actions from anywhere—call `SwifTea.dispatch(Action.someCase)` to enqueue work on the runtime thread without reaching for global state.
- Kick off background work with `SwifTea.dispatch(Effect<Action>.run { send in try await Task.sleep(...) ; send(.completed) }, id: "network", cancelExisting: true)`; use `id` to cancel or replace in-flight effects.
- Need a timer? `Effect<Action>.timer(every: 0.5) { .tick }` emits `.tick` every 500 ms until you cancel it (either explicitly via `SwifTea.cancelEffects(withID:)` or when the runtime shuts down).
- Scenes can override `initializeEffects()` to seed timers or long-lived work as soon as the runtime boots, keeping `handleFrame` free for animation-heavy cases only.

### Text Input & Focus

- Use `@State` for local data and pass `$property` to `TextField`/`TextEditor`. These views now mirror SwiftUI naming: call `.foregroundColor(_)`, `.bold()`, `.focused(_:)`, `.blinkingCursor()`, and `.focusRingStyle(_)` to customise appearance and focus behaviour.
- Reach for `@StateObject`/`@ObservedObject` when you need shared reference models (e.g., a long-lived view model or async fetcher). SwifTeaUI keeps those objects alive across re-renders, mirroring SwiftUI’s ownership semantics.
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

- `swift run SwifTeaGalleryExample` now launches focused demos: counter, form & focus, list/search, table snapshot, and overlays. Jump with `[1]`…`[5]` or `Tab`/`Shift+Tab` between sections without quitting; hit `[T]` to cycle themes (bubble tea + solarized light/dark).

### Layout Primitives

- `VStack` and `HStack` accept `spacing` and alignment arguments that mirror SwiftUI. Need a fixed height? Call `.frame(height:alignment:)` on the stack rather than passing a custom parameter.
- Call `.padding(_:)` on any view to inset the rendered output with ANSI-aware spacing.
- Wrap any view in `.foregroundColor(_:)` or `.backgroundColor(_:)` to tint entire containers (Stacks, Borders, custom composites) with ANSI colors without re-styling each child manually.
- Need curated palettes? `SwifTeaTheme` ships with `bubbleTeaDark` / `bubbleTeaLight` presets so demos (like Counter) can apply consistent accent/success/info colors and let users toggle between them.
- `ScrollView(axis:viewport:offset:)` clamps tall content (vertical) or wide buffers (horizontal) without re-rendering children. Bind `contentLength` to capture the total rows or columns, call `.followingActiveLine(_:)` (optionally with an enable binding) to auto-scroll caret positions, flip on `.scrollIndicators(.automatic)` for arrow chrome when content overflows, and use `.scrollDisabled(true)` whenever reducers need to freeze scroll state manually.
- `HStack(spacing:horizontalAlignment:verticalAlignment:)` measures ANSI widths accurately so mixed-color content still lines up.
- `AdaptiveStack(breakpoint:expanded:collapsed:)` switches entire layouts based on terminal width—use it to collapse dual-column panes into a stacked presentation without re-implementing breakpoint checks.
- `ZStack` overlays multiple views in z-order so badges/tooltips/overlays can be layered without touching the base content.
- All `TUIView` conformers expose `var body: some TUIView`; return `VStack`/`HStack` (or any other view) and the runtime calls `render()` for you—no manual `.render()` needed.

### Table Layouts

`Table` brings SwiftUI-style column definitions to the terminal. Pick from `.fixed`, `.fitContent`, or `.flex(min:max:)` widths, opt into headers/footers, and let SwifTeaUI handle ANSI-aware measurement for multi-line cells. Row styling is opt-in per index so you can emphasize focus, selections, or zebra striping:

```swift
@State private var selectedProcessIDs = Set<Process.ID>()
@FocusState private var focusedProcess: Process.ID?

Table(
    processes,
    divider: .line(color: .brightBlack, isBold: true),
    selection: .multiple($selectedProcessIDs, focused: $focusedProcess),
    rowStyle: TableRowStyle.stripedRows(
        evenStyle: TableRowStyle.stripe(backgroundColor: .brightBlack),
        oddStyle: TableRowStyle.focused(accent: .cyan)
    ),
    columns: {
        TableColumn("Name", value: \Process.name, width: .flex(min: 12)) { name in
            name.uppercased()
        }
        TableColumn("State", value: \Process.state, width: .fixed(12), alignment: .trailing)
        TableColumn("Duration", value: \Process.duration) { duration in
            "\(duration)s"
        }
    }
)
```

`TableRowStyle` now exposes underline/dim/reverse toggles plus optional borders (`▌ row ▐`) so focused rows read clearly without building ad-hoc view wrappers. Divider lines accept foreground/background colors (or a fully custom renderer) whenever you need to match a theme instead of relying on plain ASCII separators. `TableColumn(value:)` mirrors SwiftUI’s key-path sugar and pipes values through a formatter closure to avoid rewriting boilerplate `Text` views, and `selection: .single/.multiple` bindings highlight whichever IDs your reducer keeps in state (with customizable focus vs. selection styles).

### Terminal Awareness

- Wrap any view in `MinimumTerminalSize(columns:rows:fallback:)` to display a friendly message when the window is too small. Counter and Task Runner both demonstrate this pattern so users aren’t stuck staring at broken layouts.
- Call `TerminalMetrics.current()` to read the live terminal size plus derived size classes (regular/compact). Recompute inside views or store the value in state when `handleTerminalResize(from:to:)` fires.
- Scenes can override `handleTerminalResize` to react to live window changes—update layout modes, kick off reflows, or enqueue actions whenever the runtime detects a terminal resize event (the runtime handles detection and calls the hook automatically).

### SwiftUI Parity Notes

- Builders: `@TUIBuilder` now supports `if`/`if let`/`switch`/loops via `buildOptional`, `buildEither`, and `buildArray`, plus `Group { ... }` and `ForEach(data,id:)` for conditional & data-driven repetition just like `@ViewBuilder`.
- Text: `Text.foregroundColor(_:)` and `Text.bold()` match SwiftUI naming; the old `.foreground`/`.bolded()` methods remain as deprecated shims.
- Inputs: `TextEditor` is the multiline field (with `typealias TextArea` for back-compat). Both `TextField` and `TextEditor` support `.focused(_:)`, `.focusRingStyle(_:)`, `.foregroundColor(_:)`, and `.blinkingCursor()`, and `TextEditor` exposes `.cursorPosition(_:)` / `.cursorLine(_:)` so reducers can drive caret placement while scroll views keep the caret visible.
- Focus: `.focused(_:)` mirrors SwiftUI’s modifier, while focus ring visuals come from `.focusRingStyle(_:)` and `FocusRingBorder`.

### Feedback Widgets

- `Spinner` renders an animated activity indicator that follows the runtime clock—use it inline with other views or embed its output inside components like `StatusBar` when background work is in flight. Built-in styles include `.ascii`, `.braille`, `.dots`, and `.line`; prefer `.ascii` or `.dots` when targeting monochrome terminals so glyphs stay legible without color cues.
- `ProgressMeter` draws lightweight `[########----] 75%` bars sized for status strips, making it easy to surface coarse task progress without leaving the status area.
- TaskRunner demonstrates a tiny status message queue so transient updates (step started/completed) cycle through the status bar instead of scrolling the primary layout—handy for longer running workflows.
- `OverlayPresenter` plus `OverlayHost` turns transient notifications and blocking modals into declarative components. Register toasts via `presentToast(duration:style:content:)`, tick them in your scene’s `handleFrame(deltaTime:)`, and wrap the root view in `OverlayHost` so the presenter draws toast stacks and modal dialogs automatically.
