
public struct MinimumTerminalSize<Content: TUIView, Fallback: TUIView>: TUIView {
    public typealias Body = Never

    private let required: TerminalSize
    private let content: Content
    private let fallback: (TerminalSize) -> Fallback

    public init(
        columns: Int,
        rows: Int,
        content: () -> Content,
        fallback: @escaping (TerminalSize) -> Fallback
    ) {
        self.required = TerminalSize(columns: columns, rows: rows)
        self.content = content()
        self.fallback = fallback
    }

    public var body: Never {
        fatalError("MinimumTerminalSize has no body")
    }

    public func render() -> String {
        let size = TerminalDimensions.current
        guard size.columns >= required.columns, size.rows >= required.rows else {
            return fallback(size).render()
        }

        return content.render()
    }
}

public extension TUIView {
    func minimumTerminalSize<Fallback: TUIView>(
        columns: Int,
        rows: Int,
        fallback: @escaping (TerminalSize) -> Fallback
    ) -> some TUIView {
        MinimumTerminalSize(columns: columns, rows: rows, content: { self }) { size in
            fallback(size)
        }
    }
}
