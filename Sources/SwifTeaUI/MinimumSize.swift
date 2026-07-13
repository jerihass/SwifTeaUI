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
        render(in: RenderEnvironment.current)
    }

    public func render(in context: RenderContext) -> String {
        let size = TerminalDimensions.current
        guard size.columns >= required.columns, size.rows >= required.rows else {
            return fallback(size).render(in: context)
        }

        return content.render(in: context)
    }
}

extension TUIView {
    public func minimumTerminalSize<Fallback: TUIView>(
        columns: Int,
        rows: Int,
        fallback: @escaping (TerminalSize) -> Fallback
    ) -> some TUIView {
        MinimumTerminalSize(
            columns: columns,
            rows: rows,
            content: { self },
            fallback: { size in fallback(size) }
        )
    }
}
