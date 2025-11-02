import Foundation

public struct CursorBlinker {
    public static var shared = CursorBlinker()

    public var isEnabled: Bool = true
    public var interval: TimeInterval = 0.5
    public var forcedVisibility: Bool? = nil
    public var timeProvider: () -> TimeInterval = {
        ProcessInfo.processInfo.systemUptime
    }

    public init() {}

    public func cursor(for base: String) -> String {
        guard !base.isEmpty else { return base }

        if let forcedVisibility {
            return forcedVisibility ? base : Self.hiddenCursor(for: base)
        }

        guard isEnabled, interval > 0 else { return base }

        let elapsed = timeProvider()
        let phase = Int((elapsed / interval).rounded(.towardZero)) % 2
        return phase == 0 ? base : Self.hiddenCursor(for: base)
    }

    private static func hiddenCursor(for base: String) -> String {
        String(repeating: " ", count: base.count)
    }
}
