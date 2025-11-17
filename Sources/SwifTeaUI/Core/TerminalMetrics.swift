import Foundation

public struct TerminalMetrics: Sendable, Equatable {
    public enum SizeClass: Sendable, Equatable {
        case compact
        case regular
    }

    public let size: TerminalSize
    public let horizontalSizeClass: SizeClass
    public let verticalSizeClass: SizeClass

    public init(
        size: TerminalSize,
        compactWidthThreshold: Int = 100,
        compactHeightThreshold: Int = 30
    ) {
        self.size = size
        self.horizontalSizeClass = size.columns < compactWidthThreshold ? .compact : .regular
        self.verticalSizeClass = size.rows < compactHeightThreshold ? .compact : .regular
    }

    public static func current(
        compactWidthThreshold: Int = 100,
        compactHeightThreshold: Int = 30
    ) -> TerminalMetrics {
        TerminalMetrics(
            size: TerminalDimensions.current,
            compactWidthThreshold: compactWidthThreshold,
            compactHeightThreshold: compactHeightThreshold
        )
    }

    public var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
}
