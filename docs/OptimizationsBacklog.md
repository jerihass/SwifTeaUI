# Optimizations Backlog

- **Perf harness** (done)
  - Adds a micro-benchmark that renders the Gallery scene in a loop and records build + write timings to validate the optimizations below before rollout.
- **Adaptive render loop** (done)
  - Track a “render needed” flag driven by model updates/effects and terminal resize, and sleep on I/O otherwise to avoid building frames every tick. Add idle FPS throttle to reduce CPU when idle.
- **Terminal size change detection**
  - Handle SIGWINCH to mark size dirty and query only on change instead of ioctl every frame.
- **Line-diff renderer**
  - Replace full-frame repaint with line-level diffing: cache previous lines, reposition cursor, and repaint only changed rows. Skip padding work when column width is unchanged.
- **Render-tree caching**
  - Introduce a lightweight rendered view representation (lines + visible widths + height) reused down the tree so stacks/scrolling don’t repeatedly split/measure ANSI strings each frame.
- **ZStack merge shortcuts**
  - Cache parsed ANSI columns per line and short-circuit merges when overlay coverage is empty/blank to cut tokenization and allocations during layered rendering.
