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
| **Adaptive Panels** | Resizable or responsive layout primitives that collapse/expand with terminal width. | Planned | Explore width observation hooks, specify API for min/max widths, create demo with HStack resizing. |
| **Terminal Size Awareness** | Detect window resizing, enforce minimum sizes, and adapt rendering gracefully. | In Progress | Expand terminal metrics access beyond runtime, share minimum-size helpers with more demos, explore automatic layout compaction. |
| **Modal Overlays** | Blocking dialogs or help palettes with dimmed background and keyboard dismissal. | Planned | Draft overlay container view, decide on focus trapping, design animation-free presentation. |
| **Notification Toasts** | Non-blocking alerts stacked near header/footer with auto-dismiss timing. | Planned | Specify queueing model and default duration, build view that composes with existing layout stacks. |

## Working Notes

- Color constants should support fallback to monochrome terminals; investigate environment-driven palette selection.
- Focus management primitives (`FocusRing`, `FocusScope`) can feed into visual cues when a view registers for focus updates.
- Focus ring helper and snapshot utilities landed; migrate remaining demos as they gain focus cues.
- Spinner component (`Spinner`) and TaskRunner demo cover animated progress; gather feedback on additional glyph sets (especially ASCII-safe variants) and expand timer customization guidance.
- Consider documenting keybindings alongside UI so components surface expected inputs (e.g., Tab order, shortcut hints).
- API polish: align surface naming with SwiftUI (e.g., `.foregroundColor`, `.bold`, `.focused` modifiers, rename `TextArea` → `TextEditor`), expand `TUIBuilder` with `buildOptional/buildEither/buildArray` for familiar control flow, and expose sizing helpers via modifiers (`.padding`, `.frame`) instead of bespoke initialiser params.
- Unify example layouts under shared containers so padding/borders read as a single frame (e.g., notebook panes sharing one border with internal padding, counter header wrapped in a bordered stack).
- Document spinner guidance for monochrome terminals and consider ASCII-only presets.

Add new sections as patterns move into design or implementation, including links to PRs, commits, and demos.
