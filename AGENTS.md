# Repository Guidelines

## Project Structure & Module Organization
SwifTeaUI is organised as a Swift Package. `Sources/SwifTeaUI/Core` hosts the render loop, effect pipeline, and shared state utilities while the rest of `Sources/SwifTeaUI` layers the declarative view DSL on top of the same module. Example apps live under `Sources/Examples`, with `Sources/Examples/Gallery` wired to the `SwifTeaGalleryExample` executable so you can iterate quickly. Tests are split between `Tests/SwifTeaCoreTests` and `Tests/SwifTeaUITests`; add mirrors of any new module APIs here to keep coverage balanced.

## Build, Test, and Development Commands
Run `swift package resolve` whenever dependencies change. `swift build` compiles all libraries and the example executable. `swift test` executes the swift-testing suite. To try the sample UI in a terminal, use `swift run SwifTeaGalleryExample`. For focused debugging, `swift test --filter StateTests` is useful when iterating on state management logic.

## Coding Style & Naming Conventions
Follow standard Swift API Design Guidelines: types in UpperCamelCase, members and functions in lowerCamelCase, and enum cases in lowerCamelCase. Prefer structs and immutable state unless modelling shared mutable data. Indent with four spaces and wrap lines around 120 columns to preserve readability in terminals. When extending the DSL, mirror existing naming such as `TUIView` and `SwifTea`. Keep example files minimal and runnable.

## Testing Guidelines
Use the `swift-testing` framework that is already imported in the suite. Group tests by feature module and describe expectations via the `@Test("…")` attribute so failures read well. Every new reducer or view helper should include a regression test: capture both initial render output and mutations, similar to `StateTests`. Add shared helpers under the relevant `Tests/...` directory rather than production targets.

## Commit & Pull Request Guidelines
Commits in history use concise, present-tense statements (e.g., `Move test helpers to test file.`); follow that pattern and scope each commit to one logical change. Before opening a PR, run `swift test` and the counter example to confirm manual behaviour. Provide a short summary, note any terminal recording or screenshots for visual tweaks, and link related issues so maintainers can trace the change quickly.
