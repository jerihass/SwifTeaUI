# Examples Revamp Plan

Goal: keep demos focused, simple, and clean while retaining the Gallery as the entry point.

## Principles

- One concept per demo; avoid piling multiple features into a single screen.
- Minimal boilerplate so readers can copy-paste and tinker.
- Showcase current components (not speculative APIs) with realistic but tiny data.
- Keep navigation predictable: consistent shortcuts, clear focus cues, and concise status hints.

## Proposed Lineup (within Gallery)

1) **Counter & State Basics** — `@State`, actions, effects/timers; shows a status bar hint and focus ring.
2) **Form & Focus** — TextField/TextEditor, validation hints, `@FocusState` navigation, and focus scope demo.
3) **List & Search** — Small list with incremental filter and highlighted matches; demonstrates diffing toggle.
4) **Table Snapshot** — Table with 3–4 columns, zebra striping, single selection, and scroll viewport.
5) **Overlays & Notifications** — Toast + modal presets via `OverlayPresenter`; includes async action integration.
6) **Responsive Layout** — AdaptiveStack breakpoint swap between split and stacked panes; shows theme toggle.
7) **Scroll & Editor** — Vertical/horizontal ScrollView with caret-following TextEditor to show viewport helpers.

Keep Notebook/TaskRunner/PackageList content only if it clearly maps to one of the focused slots above; otherwise archive them into a “legacy” folder outside the default Gallery.

## Next Actions

- Trim Gallery sections to the lineup above; rename tiles to the feature they illustrate.
- Add a lightweight landing card in each demo describing the concept and key bindings.
- Unify keybindings across demos (`Tab`/`Shift+Tab` for sections, digits 1–9 for direct jumps, `?` for help).
- Refresh README “Examples” section to mirror the new lineup once implemented.

## Current Status

- Gallery now shows the focused set: counter, form/focus, list/search, table snapshot, and overlay presets with unified keybindings and help modal.
- README examples section mirrors the new lineup; further responsive/scroll demos can be added in follow-up iterations.
