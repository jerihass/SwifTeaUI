import Foundation

public struct AdaptiveStack<Expanded: TUIView, Collapsed: TUIView>: TUIView {
    public typealias Body = Never

    private let breakpoint: Int
    private let expandedBuilder: () -> Expanded
    private let collapsedBuilder: () -> Collapsed

    public init(
        breakpoint: Int,
        expanded: @escaping () -> Expanded,
        collapsed: @escaping () -> Collapsed
    ) {
        self.breakpoint = breakpoint
        self.expandedBuilder = expanded
        self.collapsedBuilder = collapsed
    }

    public var body: Never {
        fatalError("AdaptiveStack has no composed body")
    }

    public func render() -> String {
        // Use the refreshed size so temporary overrides (e.g., tests/previews) are honored.
        let columns = TerminalDimensions.refresh().columns
        if columns >= breakpoint {
            return expandedBuilder().render()
        } else {
            return collapsedBuilder().render()
        }
    }
}
