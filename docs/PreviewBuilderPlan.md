## Preview Builder/Provider Plan

### Goals

- Provide a lightweight way to render any `TUIView` or `TUIScene` without launching the full `SwifTea` runtime loop so terminals, editors, and CI snapshots can reuse the same fixtures.
- Mirror SwiftUI’s `PreviewProvider` ergonomics so Xcode users can define previews once, while still being able to invoke them from CLI tooling (e.g., Neovim command, `swift run PreviewDemo`).
- Keep previews modular: no global singletons, and able to vend multiple preview entries per feature (Notebook, Task Runner, etc.).

### Requirements

1. **Unified definition site** – Authors declare previews next to their models/scenes so both Xcode and CLI harnesses import them.
2. **View + Scene support** – Some previews only need a composable `TUIView`; others want to spin up a scene with canned model state. Both must be supported.
3. **Editor-neutral renderer** – Provide a pure Swift API that returns ANSI strings (or structured frames) so downstream tools decide how to display (Xcode canvas, Neovim split, cat > terminal).
4. **Deterministic fixtures** – Hooks to inject terminal size, mock time, disable effects so previews remain stable.

### Proposed API Surface

```swift
public struct TUIViewPreview {
    public let name: String
    public let category: String?
    public let size: TerminalSize?
    private let builder: () -> AnyTUIView

    public func makeView() -> AnyTUIView { builder() }
    public func render() -> String
}

public protocol TUIViewPreviewProvider {
    @PreviewBuilder static var previews: [TUIViewPreview] { get }
}
```

#### Helpers

- `PreviewBuilder` result builder to make declarations terse.
- `PreviewCatalog` utility that collects every `TUIViewPreviewProvider` registered in a target (Xcode can statically reference a list; CLI can reflect via manual array).
- `ScenePreview<App: TUIScene>` helper that runs `view(model:)` once with a supplied model (bypasses runtime loop) and returns `AnyTUIView`.

#### Sample Declarations

```swift
struct NotebookPreviews: TUIViewPreviewProvider {
    static var previews: [TUIViewPreview] {
        Preview("Default Note") {
            NotebookScene(model: NotebookModel()).view(model: NotebookModel())
        }
        Preview.scene("Focused Editor") {
            var model = NotebookModel(focusedField: .editorBody)
            return (model.makeView(), model) // builder will freeze render
        }
    }
}
```

### Environment/Runtime Hooks

- `PreviewRenderer.render(preview: TUIViewPreview, terminalSize: TerminalSize?) -> String` handles temporarily overriding `TerminalDimensions` so layout behaves.
- `PreviewRuntime` disables `Effect` dispatch and timers; previews should never run async work—builder receives synchronous model and returns view.

### Integration Sketch

1. **Xcode** – Add a tiny `macOS` target that imports preview providers and surfaces them to SwiftUI Preview Canvas via `NSViewRepresentable` or logs frames into canvas (requires follow-up).
2. **CLI/Neovim** – Expose `swift run PreviewDemo --list` and `--preview Notebook:Focused Editor`. CLI command enumerates `PreviewCatalog` and prints frames or streams to watchman. _Status: implemented via `swift run SwifTeaPreviewDemo` (see below)._

### CLI Runner

- `swift run SwifTeaPreviewDemo --list` lists all registered previews (currently the Hello World and Counter demos).
- `swift run SwifTeaPreviewDemo --preview "Hello World"` renders the selected preview; add `--size 100x30` to override the terminal dimensions for quick testing inside editors or Neovim splits.

### Next Steps

1. Land the core types (`TUIViewPreview`, `PreviewBuilder`, `PreviewRenderer`, `ScenePreview`).
2. Add a small CLI entry point (even `swift run PreviewDemo Notebook/default`) to validate the API.
3. Gradually retrofit Hello World / Counter Demo modules to declare preview providers and feed them into snapshot tests/Xcode integration later.
