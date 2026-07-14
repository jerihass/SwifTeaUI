import Foundation

public struct CursorBlinker: Sendable {
    private static let storage = CursorBlinkerStorage()

    public static var shared: CursorBlinker {
        get { storage.get() }
        set { storage.set(newValue) }
    }

    public var isEnabled: Bool = true
    public var interval: TimeInterval = 0.5
    public var forcedVisibility: Bool? = nil
    public var timeProvider: @Sendable () -> TimeInterval = {
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

private final class CursorBlinkerStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var value = CursorBlinker()

    func get() -> CursorBlinker {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ value: CursorBlinker) {
        lock.lock()
        self.value = value
        lock.unlock()
    }
}
