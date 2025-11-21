import Foundation

public protocol TUIView {
    associatedtype Body: TUIView
    var body: Body { get }
    func render() -> String
}

/// A lightweight rendering result carrying lines and dimensions, used to avoid
/// repeated splitting/measuring during layout composition.
struct RenderedView {
    var lines: [String]
    var widths: [Int] // visible width per line

    init(lines: [String]) {
        self.lines = lines
        self.widths = lines.map { HStack.visibleWidth(of: $0) }
    }

    var height: Int { lines.count }
    var maxWidth: Int { widths.max() ?? 0 }

    func joined() -> String {
        lines.joined(separator: "\n")
    }
}

/// Internal hook for views that can hand back a precomputed render without re-splitting.
protocol RenderedViewProvider {
    var renderedViewSnapshot: RenderedView? { get }
}

/// Resolve a view into a measured render, reusing cached snapshots when available.
func resolveRenderedView(for view: any TUIView) -> RenderedView {
    if let provider = view as? RenderedViewProvider, let cached = provider.renderedViewSnapshot {
        return cached
    }
    return RenderedView(lines: view.render().splitLinesPreservingEmpty())
}

struct CachedRenderedView: TUIView, RenderedViewProvider {
    typealias Body = Never

    let snapshot: RenderedView

    var renderedViewSnapshot: RenderedView? { snapshot }

    var body: Never {
        fatalError("CachedRenderedView has no body")
    }

    func render() -> String {
        snapshot.joined()
    }
}

public extension TUIView {
    func render() -> String {
        body.render()
    }
}

extension Never: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public func render() -> String {
        fatalError("Never cannot render")
    }
}

public protocol TUIScene {
    associatedtype Model = Self
    associatedtype Action = Never
    associatedtype Content: TUIView

    var model: Model { get }
    func view(model: Model) -> Content

    mutating func update(action: Action)
    mutating func initializeEffects()
    mutating func handleTerminalResize(from oldSize: TerminalSize, to newSize: TerminalSize)
    func mapKeyToAction(_ key: KeyEvent) -> Action?
    func shouldExit(for action: Action) -> Bool
    mutating func handleFrame(deltaTime: TimeInterval)
}

@resultBuilder
public enum TUISceneBuilder {
    public static func buildBlock<Content: TUIScene>(_ content: Content) -> Content {
        content
    }
}

public extension TUIScene {
    mutating func initializeEffects() {}
    mutating func handleTerminalResize(from oldSize: TerminalSize, to newSize: TerminalSize) {}
    mutating func handleFrame(deltaTime: TimeInterval) {}
}
