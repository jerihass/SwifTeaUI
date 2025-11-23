# SwifTeaUI Quickstart

This is the shortest path to render your first terminal UI, wire keyboard input, and explore the demos.

## 1) Install & Build

- Requires Swift 5.9+ (Xcode 15 or recent Swift toolchain on Linux).
- From the repo root run:
  - `swift package resolve`
  - `swift build`

## 2) Run the Gallery

- `swift run SwifTeaGalleryExample`
- Navigate sections with `[1]`…`[6]` or `Tab`/`Shift+Tab`.
- List selection: checkboxes (`w`/`s`/Space) and radio list (`a`/`d`/Enter) live under “List Selection”.
- Hit `[T]` to flip themes; `[?]` opens inline help.

## 3) Minimal App Skeleton (Model + View split)

```swift
import SwifTeaUI

@main
struct MyApp: TUIApp {
    var body: some TUIScene { Scene() }
}

struct Scene: TUIScene {
    typealias Model = ModelState
    typealias Action = ModelState.Action
    var model = ModelState()

    mutating func update(action: Action) { model.update(action: action) }
    func view(model: ModelState) -> some TUIView { CounterView(count: model.count) }
    func mapKeyToAction(_ key: KeyEvent) -> Action? { model.mapKeyToAction(key) }
    func shouldExit(for action: Action) -> Bool { model.shouldExit(for: action) }
}

struct ModelState {
    enum Action { case increment, decrement, quit }
    @State private(set) var count = 0

    var countValue: Int { count }

    mutating func update(action: Action) {
        switch action {
        case .increment: count += 1
        case .decrement: count -= 1
        case .quit: break
        }
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .rightArrow, .char("+"): return .increment
        case .leftArrow, .char("-"): return .decrement
        case .char("q"), .escape: return .quit
        default: return nil
        }
    }

    func shouldExit(for action: Action) -> Bool { action == .quit }
}

struct CounterView: TUIView {
    let count: Int

    var body: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("Count: \(count)").foregroundColor(.green).bold()
            Text("←/→ or +/- to change, q to quit").foregroundColor(.cyan)
        }
        .padding(1)
        .focusRing(isFocused: true)
    }
}
```

- Key ideas: `@State` keeps values live between renders; the reducer (`update`) mutates state; `mapKeyToAction` converts terminal keys to actions; the view (`CounterView`) is a pure render of the model’s data.

## 4) Common Controls & Patterns

- **Text input**: `TextField` / `TextEditor` bound to `@State` string, optionally `@FocusState` for caret routing; add `.blinkingCursor()` for visibility.
- **Lists & tables**: `List` and `Table` accept `selection: .single/.multiple` with optional focused row bindings; styles come from `TableRowStyle`.
- **Focus**: use `@FocusState` and `FocusRing`/`FocusScope` to manage Tab/Shift+Tab traversal; `.focusRingStyle(_:)` sets visuals.
- **Effects**: dispatch async work via `Effect` and `SwifTea.dispatch` from reducers; cancel with `SwifTea.cancelEffects(withID:)`.

## 5) Designing Models & Views

- **Loop like Elm/Bubble Tea**: keep all app state in your scene model, mutate it in `update(action:)`, and derive actions from `mapKeyToAction(_:)`. Effects are explicit and cancelable.
- **Render like SwiftUI**: views are pure functions of data. Pass only what’s needed (e.g., `CounterView(count:)`), avoid side effects in `render()`, and let the runtime re-render on state changes.
- **Local vs shared state**: prefer `@State` inside the model for business data; use `@StateObject`/`@ObservedObject` for shared reference types. Keep view-scoped `@State` small and UI-local.
- **Input flow**: map keys → actions → reducer updates state → views re-render. Do not mutate model state from inside views.
- **Composition**: build small views that take values/bindings; it keeps re-renders cheap and makes the reducer easy to test.

## 6) Troubleshooting

- If ANSI colors look off, check terminal supports 256 colors/truecolor.
- On macOS sandboxed shells, SwiftPM may need write access to `~/Library/Caches/org.swift.swiftpm`; rerun commands outside restricted shells.
- Resize handling: override `handleTerminalResize` in your scene to react to window changes; wrap content in `MinimumTerminalSize` to show a friendly fallback.
