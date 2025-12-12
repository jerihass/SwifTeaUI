# Input Ergonomics Plan

This document proposes an incremental roadmap for making SwifTeaUI input handling feel more SwiftUI‑native
while keeping views pure (no direct key binding awareness) and preserving the current unidirectional update
loop. The intent is to reduce boilerplate in `mapKeyToAction(_:)` without turning the framework into a
focus‑mystery black box.

## Context

Today, input is routed entirely at the scene/model layer:

- `SwifTea.brew` reads raw `KeyEvent`s and calls `TUIScene.mapKeyToAction(_:)`.
- Example apps define large `switch key { … }` blocks plus manual focus branching.
- Widgets such as `TextField` and `TextArea` expose semantic events (e.g. `TextFieldEvent`) but the glue
  from `KeyEvent` to those events is written by each app.
- `@FocusState`, `FocusRing`, and `FocusScope` exist, but are not used as an input router; apps re‑implement
  routing based on `focusedField`.

The architecture is sound, but ergonomics degrade quickly as apps grow or nest sub‑models.

## Goals

- Preserve purity: `TUIView` render trees must not depend on key codes or terminal input sources.
- Keep routing explicit and testable: apps should be able to reason about which inputs map to which actions.
- Reduce boilerplate for common patterns: global shortcuts, focused subtrees, and standard control behavior.
- Enable composable input definitions across nested models (Gallery‑style delegation).
- Stay additive: existing apps and APIs continue to work unchanged.

## Design Details

These details refine the phases below and should be implemented alongside Phase 1/2 to keep behavior
deterministic and discoverable.

### Conflict resolution & precedence

- `KeyMap.map(_:)` returns the first matching entry in declaration order.
- `merging(_:)` preserves left‑to‑right priority: `a.merging(b)` consults `a` first, then `b`.
- `fallback(_:)` only runs if no prior entry matches.
- `KeyRouter` supports two explicit policies:
  - **focusedFirst** (default): focused route wins unless global also matches a reserved key.
  - **globalFirst**: global route wins, useful for always‑on app shortcuts.
- Reserved global keys should be documented (e.g., `.ctrlC`) so apps can rely on consistent escape hatches.

### Discoverability & help generation

To avoid drift between help UI and real behavior, `KeyMap` entries should optionally carry metadata:

- `label`: short description (e.g., "Quit", "Next item").
- `category`: grouping for help sheets/status bars (e.g., "Global", "Navigation", "Editing").
- `showInHelp`: opt‑out for hidden bindings.

This allows the Gallery help modal and any future status/command bar to be generated from the same source.

### Key normalization

- `.char("t")` and `.char("T")` are distinct by default.
- Provide a case‑insensitive matcher helper (e.g., `.char("t", caseInsensitive: true)`) to reduce boilerplate
  for common shortcuts.
- If a normalization layer is added later, keep it opt‑in so apps can choose strictness.

### Mode/state‑driven maps

Keymaps must be easy to build from current model state without imperative branching:

- Use `when(_:)` to enable/disable whole maps based on state flags (search mode, modal open, etc.).
- Prefer separate maps per mode and merge them in a predictable order rather than writing “if key … else …”
  in `mapKeyToAction`.

### Extensibility boundary

Phases 1–3 target *single* `KeyEvent` mappings only.

- Chords/sequences (e.g., `g g`) should be a later, separate design once `KeyMap` settles.
- Keeping Phase 1/2 minimal reduces API churn.

### Testing guidance

Library:

- Table‑driven tests for `KeyMap` matching and combinator priority.
- Tests for `KeyRouter` precedence and focus transitions.

Apps/examples:

- Snapshot “routing tables” by asserting a list of `(KeyEvent, Action?)` pairs against expected outputs.
- Prefer focused unit tests over runtime loop tests.

## Proposed Phases

### Phase 1 — KeyMap primitive (additive)

Introduce a small, composable key mapping type in Core.

**Surface idea**

- `KeyMap<Action>`: maps `KeyEvent` to `Action?`.
- Builder syntax for readability.
- Combinators: `merging`, `when(_:)`, `lift(_:)`, `fallback(_:)`.

**Phase 1 must‑haves**

- Deterministic precedence rules (declaration order, left‑to‑right `merging`, `fallback` semantics).
- `when(_:)` to enable/disable maps based on model state.
- Table‑driven tests for matching + combinators.

**Phase 1 nice‑to‑haves**

- Optional entry metadata (`label`, `category`, `showInHelp`) if it stays lightweight.
- Case‑insensitive character matcher helper.

**Example usage (app side)**

```swift
let global: KeyMap<Action> = KeyMap {
    (.ctrlC, .quit)
    (.char("q"), .quit)
    (.enter, .startSelected)
}

let navigation: KeyMap<Action> = KeyMap {
    (.upArrow, .moveFocus(-1))
    (.downArrow, .moveFocus(1))
}

func mapKeyToAction(_ key: KeyEvent) -> Action? {
    global.merging(navigation).map(key)
}
```

**Benefits**

- Turns most `switch key` blocks into declarative tables.
- Provides a standard way to merge global shortcuts with local behavior.
- Minimal risk; no changes to runtime or rendering.

**Next steps**

- Implement in `Sources/SwifTeaUI/Core`.
- Refactor `TaskRunnerModel.mapKeyToAction` to validate ergonomics.
- Add small Core tests for mapping and combinators.

### Phase 2 — Focus‑aware KeyRouter

Build on Phase 1 to standardize focus routing without view knowledge.

**Surface idea**

- `KeyRouter<FocusID, Action>` where `FocusID: Hashable`.
- Initialized with a focus binding and per‑focus `KeyMap`s plus a global map.
- Configurable precedence: global‑first vs focused‑first.

**Example usage**

```swift
let router = KeyRouter(
    focus: $focusedField.binding,
    global: globalMap,
    routes: [
        .sidebar: sidebarMap,
        .editorTitle: titleMap,
        .editorBody: bodyMap
    ]
)

func mapKeyToAction(_ key: KeyEvent) -> Action? {
    router.map(key)
}
```

**Benefits**

- Removes per‑app “if focusedField == …” branching.
- Encourages consistent focus behavior across demos.
- Still explicit: routing tables live in models.

**Next steps**

- Implement router in Core.
- Refactor `NotebookModel.mapKeyToAction` to use router.
- Add tests for precedence and nil focus behavior.

### Phase 3 — Semantic keymaps for controls

Ship default keymaps that output semantic events, not actions.

**Targets**

- `TextField.keyMap -> TextFieldEvent`
- `TextArea.keyMap -> TextFieldEvent` (or a richer multiline editor event later).
- `List/Table` navigation keymaps (move selection, activate, toggle selection).

**Pattern**

- Controls remain pure renderers.
- Apps lift semantic events into actions:

```swift
let titleMap = TextField.keyMap.lift(Action.editTitle)
```

**Benefits**

- Apps stop re‑writing common key handling.
- Encourages shared interaction conventions.

**Next steps**

- Wrap existing `textFieldEvent(from:)` in a keymap.
- Add list/table semantic events + keymaps when selection APIs are stable.
- Update docs/QUICKSTART to show the pattern.

### Phase 4 — Optional component scoping sugar

Reduce boilerplate for nested models (Gallery sections).

**Surface idea**

- Lightweight “scope” helper that pairs:
  - child state slice
  - child update
  - child keymap
  - action lifting

This is optional, and should follow successful validation of Phases 1–3.

## Non‑Goals

- No direct `.onKey` or raw key bindings on `TUIView`.
- No implicit responder chain hidden in the render tree.
- No requirement for apps to adopt new APIs; `mapKeyToAction` stays supported.

## Rollout Plan

- Land Phase 1 behind additive types and refactor one example.
- Gather feedback on ergonomics and naming.
- Land Phase 2 and refactor a focus‑heavy example.
- Land Phase 3 for text input first; expand to list/table once their semantics settle.
- Cross‑link this plan from `docs/TUIDesignRoadmap.md` under Focus & Navigation and Status/Command Bar.

## Open Questions

- Naming: `KeyMap`, `KeyBindings`, or `InputMap`?
- Precedence defaults for router: should global keys always win, or should focus own the keys unless opted out?
- Should keymaps allow chord/sequence support later (e.g., `g g`), or stay single‑event only?
- How much metadata belongs in the Core `KeyMap` type vs. a higher‑level help/command layer?
