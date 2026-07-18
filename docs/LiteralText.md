# Literal-safe terminal text

Terminal output is an execution boundary: C0/C1 control scalars, DEL, and ANSI
escape sequences can move the cursor, recolor later output, clear the screen, or
change terminal metadata. SwifTeaUI therefore treats ordinary text content as
literal data by default.

```swift
Text(importedName)
TextSpan(userNotes)
TextField("Opponent", text: $opponent)
TextEditor("Notes", text: $notes)
```

Before measurement or layout, these views replace each C0/C1 control scalar and
DEL with U+FFFD. `Text`, `TextSpan`, and `TextEditor` preserve authored line
feeds; the single-line `TextField` replaces them. Text fields and editors render
a safe copy without changing the bound value, and caret offsets remain expressed
in the authored string's grapheme positions.

Framework or application code that has deliberately assembled ANSI presentation
can opt into the auditable trusted path:

```swift
let styled = ANSIColor.yellow.rawValue + "Ready" + ANSIColor.reset.rawValue
Text(trustedANSI: styled)
```

Never pass imported, user-authored, network-provided, or persisted data to
`Text(trustedANSI:)`. Prefer normal `Text` plus SwifTeaUI style modifiers whenever
possible. Rich text should use `TextSpan` styles rather than embedded ANSI.

This contract protects rendering, not storage. Applications may retain raw
values for round trips, validation, or diagnostics while presenting them safely.
