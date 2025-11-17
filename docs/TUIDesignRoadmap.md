# TUI Design Roadmap

This document tracks upcoming terminal UI design paradigms for SwifTeaUI. Each entry captures the user experience goal, technical scope, and next actions so we can iterate deliberately.

## Goals

- Offer consistent affordances that help users understand focus, navigation, and feedback across demos.
- Provide reusable primitives inside `SwifTeaUI` so app authors assemble rich layouts without bespoke logic.
- Maintain straightforward theming hooks to adapt color palettes or glyphs for different terminal environments.

## Patterns Backlog

| Pattern | Purpose | Status | Next Steps |
| --- | --- | --- | --- |
| **Status & Command Bar** | Persistent footer for live state, modes, and shortcut hints. | Implemented | Harden `StatusBar` width handling, roll out to additional demos, document customization knobs. |
| **Focus & Navigation Cues** | Unifies how focused panes, selected rows, and cursor locations render. | Implemented | Roll focus ring helper into future demos, expand snapshot helpers for additional layouts, document cursor customization knobs. |
| **Activity Indicator** | Animated spinner glyphs for background work and progress. | Implemented | Showcase `Spinner` across demos, offer presets for alternate glyph sets, and document integration with status bars. |
| **Progress Meter** | Visualises coarse task completion percentages inline with status bars. | Implemented | Expose width/fill customisation, explore stacked meters for multi-task dashboards. |
| **Async Action Effects** | Allow background tasks (network calls, timers, Task sleep) to emit reducer Actions without manual polling. | Implemented | Document `Effect.run`/`Effect.timer` patterns, add cancellation helpers for grouped work, and roll SwifTea's dispatch APIs into the other demos so long-lived tasks avoid `handleFrame` polling. |
| **Terminal Size Awareness** | Detect window resizing, enforce minimum sizes, and adapt rendering gracefully. | Implemented | Gather feedback on size-class thresholds, expose configurable breakpoints if needed, and expand adaptive layouts to additional demos. |
| **Adaptive Panels** | Resizable layout primitives that respond to the size metrics above. | Planned | Provide width observers, min/max constraints, and a demo showing live column collapse/expand. |
| **Notification & Overlay System** | Non-blocking toasts plus blocking modals built on a shared overlay stack. | Implemented | `OverlayPresenter` + `OverlayHost` now handle toast placement, modal rendering, and timed dismissal; extend styles or behaviors by composing new overlay builders. |
| **Preview Builders** | Declarative wrappers that hydrate scenes/models with canned state for demos/tests. | Planned | Design lightweight builder API (e.g., `CounterScene.preview(state:)`), ensure builders can run `TUIScene` without the full runtime, and share fixtures between previews & snapshot tests. |
| **Intrinsic View Measurements** | Teach views to report their rendered footprint so layouts adapt automatically. | Planned | Define a `sizeThatFits` API alongside `render()`, update Text/HStack/VStack/Border to return ANSI-aware sizes, and let helpers like `MinimumTerminalSize` derive thresholds dynamically. |
| **Observable State Objects** | Property wrapper + observation hooks for class-based models (`@StateObject` analog). | Planned | Define observable protocol + lifecycle, ensure reference mutations trigger re-render safely, and document reducer interaction/testing strategy. |
| **ForEach Diffing** | Re-render only changed elements by leveraging user-provided IDs. | Planned | Track IDs per element, compare against prior frame, and emit minimal updates once runtime supports partial rendering. |
| **Table Layout Component** | Provide a declarative table/grid view with column definitions, headers, and alignment options. | Implemented | `Table` + `TableColumn` now cover measurement, dividers, and row styling; next polish is diff-aware updates and richer docs/screenshots (see the package dashboard inside `SwifTeaGalleryExample`). |
| **View Background Modifiers** | Allow containers (HStack/VStack/etc.) to apply foreground/background colors. | Implemented | `.foregroundColor(_:)` / `.backgroundColor(_:)` now wrap any view’s rendered output with ANSI escapes. Next: document precedence with nested styled children and add theming helpers for preset palettes. |
| **Additional Text Styles** | Add `.strikethrough()`, `.dim()`, `.inverse()` to mirror ANSI capabilities. | Planned | Extend `Text` modifiers + tests, and decide whether to expose generic view modifiers for these styles. |
| **Scrollable Viewports** | Keep text editors and long content bounded via scroll containers that mirror SwiftUI’s `ScrollView`. | Implemented | `ScrollView` now supports horizontal slicing, indicator glyphs, `.followingActiveLine` helpers, and `.scrollDisabled(_:)` so reducers can freeze offsets. Next polish: experiment with indicator theming, add caret-column auto-follow options, and showcase the new APIs across additional demos. |
| **Theme Presets** | Ship curated color palettes so demos share cohesive styling out of the box. | Implemented | `SwifTeaTheme` exposes bubbleTea dark/light plus the new neon palette; next explore runtime theme toggles, monochrome fallbacks, and documenting palette guidelines. |

## Working Notes

- Color constants should support fallback to monochrome terminals; investigate environment-driven palette selection.
- Focus management primitives (`FocusRing`, `FocusScope`) can feed into visual cues when a view registers for focus updates.
- Focus ring helper and snapshot utilities landed; migrate remaining demos as they gain focus cues.
- Spinner component (`Spinner`) and TaskRunner demo cover animated progress; gather feedback on additional glyph sets (especially ASCII-safe variants) and expand timer customization guidance.
- Progress meter (`ProgressMeter`) now drives status strip percentages—consider colour-aware theming and stacked meters for concurrent tasks.
- OverlayPresenter/OverlayHost now drive toasts + modals; migrate remaining demos from bespoke queues (e.g., TaskRunner) and surface reusable overlay presets (help sheets, confirmations, etc.).
- Consider documenting keybindings alongside UI so components surface expected inputs (e.g., Tab order, shortcut hints).
- API polish: align surface naming with SwiftUI (e.g., `.foregroundColor`, `.bold`, `.focused` modifiers, rename `TextArea` → `TextEditor`), expand `TUIBuilder` with `buildOptional/buildEither/buildArray` for familiar control flow, and expose sizing helpers via modifiers (`.padding`, `.frame`) instead of bespoke initialiser params.
- Unify example layouts under shared containers so padding/borders read as a single frame (e.g., notebook panes sharing one border with internal padding, counter header wrapped in a bordered stack).
- Document spinner guidance for monochrome terminals and consider ASCII-only presets.

Add new sections as patterns move into design or implementation, including links to PRs, commits, and demos.
