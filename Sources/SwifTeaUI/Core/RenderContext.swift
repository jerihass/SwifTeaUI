public struct ProposedViewSize: Equatable, Sendable {
    public var width: Int?
    public var height: Int?

    public init(width: Int? = nil, height: Int? = nil) {
        self.width = width.map { max(0, $0) }
        self.height = height.map { max(0, $0) }
    }

    public static let unspecified = ProposedViewSize()

    public func inset(horizontal: Int = 0, vertical: Int = 0) -> ProposedViewSize {
        ProposedViewSize(
            width: width.map { max(0, $0 - max(0, horizontal)) },
            height: height.map { max(0, $0 - max(0, vertical)) }
        )
    }
}

public struct RenderContext: Equatable, Sendable {
    public var proposedSize: ProposedViewSize
    public var fillsProposedWidth: Bool

    public init(
        proposedSize: ProposedViewSize = .unspecified,
        fillsProposedWidth: Bool = false
    ) {
        self.proposedSize = proposedSize
        self.fillsProposedWidth = fillsProposedWidth
    }

    public static let unspecified = RenderContext()
}

enum RenderEnvironment {
    @TaskLocal static var current = RenderContext.unspecified
}
