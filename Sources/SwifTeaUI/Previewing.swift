import Foundation

public struct TUIViewPreview {
    public let name: String
    public let category: String?
    public let size: TerminalSize?

    private let builder: () -> AnyTUIView

    public init<V: TUIView>(
        _ name: String,
        category: String? = nil,
        size: TerminalSize? = nil,
        _ makeView: @escaping () -> V
    ) {
        self.name = name
        self.category = category
        self.size = size
        self.builder = { AnyTUIView(makeView()) }
    }

    public static func scene<App: TUIScene>(
        _ name: String,
        category: String? = nil,
        size: TerminalSize? = nil,
        _ makeScene: @escaping () -> App
    ) -> TUIViewPreview {
        TUIViewPreview(name, category: category, size: size) {
            let scene = makeScene()
            return scene.view(model: scene.model)
        }
    }

    public func makeView() -> AnyTUIView {
        builder()
    }

    public func render(terminalSize: TerminalSize? = nil) -> String {
        let resolvedSize = terminalSize ?? size
        let renderBlock = {
            let proposal =
                resolvedSize.map {
                    ProposedViewSize(width: $0.columns, height: $0.rows)
                } ?? .unspecified
            return makeView().render(in: RenderContext(proposedSize: proposal))
        }

        if let size = resolvedSize {
            return TerminalDimensions.withTemporarySize(size, renderBlock)
        } else {
            return renderBlock()
        }
    }
}

@resultBuilder
public enum PreviewBuilder {
    public static func buildBlock(_ components: [TUIViewPreview]...) -> [TUIViewPreview] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: TUIViewPreview) -> [TUIViewPreview] {
        [expression]
    }

    public static func buildExpression(_ expression: [TUIViewPreview]) -> [TUIViewPreview] {
        expression
    }

    public static func buildOptional(_ component: [TUIViewPreview]?) -> [TUIViewPreview] {
        component ?? []
    }

    public static func buildEither(first component: [TUIViewPreview]) -> [TUIViewPreview] {
        component
    }

    public static func buildEither(second component: [TUIViewPreview]) -> [TUIViewPreview] {
        component
    }

    public static func buildArray(_ components: [[TUIViewPreview]]) -> [TUIViewPreview] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [TUIViewPreview]) -> [TUIViewPreview] {
        component
    }
}

public protocol TUIViewPreviewProvider {
    @PreviewBuilder static var previews: [TUIViewPreview] { get }
}

public struct PreviewCatalog {
    public let previews: [TUIViewPreview]

    public init(_ providers: [TUIViewPreviewProvider.Type]) {
        self.previews = providers.flatMap { $0.previews }
    }

    public func groupedByCategory() -> [String?: [TUIViewPreview]] {
        previews.reduce(into: [:]) { groups, preview in
            groups[preview.category, default: []].append(preview)
        }
    }
}

public enum PreviewRenderer {
    public static func render(
        _ preview: TUIViewPreview,
        terminalSize: TerminalSize? = nil
    ) -> String {
        preview.render(terminalSize: terminalSize)
    }
}
