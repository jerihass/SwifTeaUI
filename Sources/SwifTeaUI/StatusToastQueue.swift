
public struct StatusToast: Equatable {
    public var text: String
    public var color: ANSIColor
    public var ttl: Int

    public init(text: String, color: ANSIColor, ttl: Int) {
        self.text = text
        self.color = color
        self.ttl = max(1, ttl)
    }
}

public struct StatusToastQueue {
    private var storage: [StatusToast] = []
    public var maxCount: Int
    public var defaultTTL: Int

    public init(maxCount: Int = 3, defaultTTL: Int = 6) {
        self.maxCount = max(1, maxCount)
        self.defaultTTL = max(1, defaultTTL)
    }

    public var isEmpty: Bool { storage.isEmpty }
    public var activeToast: StatusToast? { storage.first }
    public var allToasts: [StatusToast] { storage }

    public mutating func enqueue(
        _ text: String,
        color: ANSIColor,
        ttl overrideTTL: Int? = nil,
        atFront: Bool = true
    ) {
        let ttl = overrideTTL.map { max(1, $0) } ?? defaultTTL
        let toast = StatusToast(text: text, color: color, ttl: ttl)
        if atFront {
            storage.insert(toast, at: 0)
        } else {
            storage.append(toast)
        }

        if storage.count > maxCount {
            storage.removeLast()
        }
    }

    public mutating func tick() {
        guard !storage.isEmpty else { return }
        for index in storage.indices {
            storage[index].ttl -= 1
        }
        storage.removeAll { $0.ttl <= 0 }
    }

    public mutating func clear() {
        storage.removeAll()
    }
}
