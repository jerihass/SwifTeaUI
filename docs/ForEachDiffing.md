# ForEach Diffing

Opt-in diffing lets `ForEach` reuse cached renders for unchanged elements and only re-render rows whose IDs or fingerprints change. Use it when rows are stable and expensive to build.

## When to enable
- Lists with stable IDs where most rows stay the same across frames.
- Rows that are pure/passive (no side effects in `render()`).
- Expensive row content (nested stacks, borders, tables, etc.).

Avoid diffing when row output depends on external global state (e.g. timers, random values, implicit environment) unless you supply an invalidation key.

## Usage
```swift
let view =
    ForEach(model.items, id: \.id) { item in
        HStack {
            Text(item.title)
            Text(item.detail)
        }
    }
    // Optional key to invalidate the cache when external inputs change.
    .diffing(key: model.themeVersion)
```

Notes:
- If `model.items.Element` is `Hashable`, its value is used as a fingerprint; otherwise renders refresh per frame even with diffing enabled.
- Changing the optional `key` forces all cached rows to refresh (useful when theming or other shared inputs change).
- Calling `diffing()` is opt-in; omitting it keeps the previous eager re-rendering behavior.
