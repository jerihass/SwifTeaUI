# Rich text and proposed layout

`RichText` renders styled inline content without exposing ANSI bookkeeping to applications. It accepts plain
`TextSpan` values and keep-together `InlineGroup` values, then word-wraps their combined content using an
explicit width or the width proposed by its parent.

```swift
RichText {
    InlineGroup {
        TextSpan("[").foregroundColor(.yellow)
        TextSpan("Attack").foregroundColor(.black).backgroundColor(.yellow).bold()
        TextSpan("]").foregroundColor(.yellow)
    }
    TextSpan(" Draw one card, then discard one card.")
}
```

## Layout contract

Runtime and preview roots begin each render with a `RenderContext` containing the terminal's
`ProposedViewSize`. Composed custom views forward that context through their `body` automatically. Containers
either forward the available width or subtract their own chrome: `Padding` subtracts its horizontal insets and
`Border` subtracts its borders and padding.

An unframed `HStack` child retains its intrinsic width. A `WidthFrame` makes allocation explicit:

```swift
HStack {
    sidebar.frame(width: .fixed(24))
    details.frame(width: .flexible(minimum: 30, priority: 1))
}
```

The stack reserves fixed and minimum widths, distributes remaining cells by priority toward ideal and maximum
widths, and proposes the allocation to each flexible child. Existing views that only implement `render()`
remain source compatible; existing composed views need no proposal-specific override.

## Text contract

- ANSI control sequences occupy zero terminal cells.
- Combining graphemes occupy one cell with their base.
- CJK wide/fullwidth graphemes, emoji sequences, and flags occupy two cells.
- Private-use glyphs, including Powerline symbols, occupy one cell.
- Authored newlines and blank lines are preserved.
- Words wrap across span boundaries without losing styles.
- Inline groups move as a unit whenever they fit; an oversized group splits at grapheme boundaries so no line
  exceeds its width.
- Each physical line ends with a reset when styled content is active, preventing presentation state from
  leaking into adjacent terminal output.

## Capability ownership

SwifTeaUI does not detect fonts or assign meaning to private-use glyphs. Applications select their own symbol
profile and build `InlineGroup` content accordingly. A portable profile should retain visible delimiters and
text, while a Nerd Font profile may substitute Powerline caps. Meaning must never depend on color or a glyph
alone.
