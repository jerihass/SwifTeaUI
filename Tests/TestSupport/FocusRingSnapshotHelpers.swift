import SwifTeaUI
import Testing

public struct FocusRingSnapshotAsserter {
    private let style: FocusStyle
    private let prefix: String
    private let suffix: String

    public init(style: FocusStyle = .default) {
        self.style = style
        var prefix = ""
        if let color = style.color {
            prefix += color.rawValue
        }
        if style.bold {
            prefix += "\u{001B}[1m"
        }
        self.prefix = prefix
        self.suffix = prefix.isEmpty ? "" : ANSIColor.reset.rawValue
    }

    public func wrapped(_ content: String) -> String {
        guard !prefix.isEmpty else { return content }
        return prefix + content + suffix
    }

    @discardableResult
    public func expect(
        in snapshot: String,
        contains requiredFragments: [String] = [],
        excludes disallowedFragments: [String] = []
    ) -> FocusRingSnapshotAsserter {
        for fragment in requiredFragments {
            #expect(
                snapshot.contains(wrapped(fragment)),
                "Expected focus ring to decorate \"\(fragment)\""
            )
        }

        for fragment in disallowedFragments {
            #expect(
                !snapshot.contains(wrapped(fragment)),
                "Focus ring unexpectedly decorated \"\(fragment)\""
            )
        }

        return self
    }
}
