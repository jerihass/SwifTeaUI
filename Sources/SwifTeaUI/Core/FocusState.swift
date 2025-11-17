@propertyWrapper
public struct FocusState<Value: Hashable> {
    final class Storage {
        var focusedValue: Value?
        init(_ value: Value? = nil) { self.focusedValue = value }
    }

    private var storage: Storage

    public init() {
        self.storage = Storage()
    }

    public init(wrappedValue: Value?) {
        self.storage = Storage(wrappedValue)
    }

    public var wrappedValue: Value? {
        get { storage.focusedValue }
        mutating set { storage.focusedValue = newValue }
    }

    public var projectedValue: ProjectedValue {
        ProjectedValue(storage: storage)
    }

    public struct ProjectedValue {
        fileprivate let storage: Storage

        public var binding: Binding<Value?> {
            Binding<Value?>(
                get: { storage.focusedValue },
                set: { storage.focusedValue = $0 }
            )
        }

        public func isFocused(_ value: Value) -> Binding<Bool> {
            Binding<Bool>(
                get: { storage.focusedValue == value },
                set: { isFocused in
                    if isFocused {
                        storage.focusedValue = value
                    } else if storage.focusedValue == value {
                        storage.focusedValue = nil
                    }
                }
            )
        }

        public func set(_ value: Value?) {
            storage.focusedValue = value
        }

        public func clear() {
            storage.focusedValue = nil
        }

        public func move(in ring: FocusRing<Value>, direction: FocusRing<Value>.Direction) {
            storage.focusedValue = ring.move(from: storage.focusedValue, direction: direction)
        }

        public func moveForward(in ring: FocusRing<Value>) {
            move(in: ring, direction: .forward)
        }

        public func moveBackward(in ring: FocusRing<Value>) {
            move(in: ring, direction: .backward)
        }

        @discardableResult
        public func moveForward(in scope: FocusScope<Value>) -> Bool {
            guard let current = storage.focusedValue, scope.contains(current) else { return false }
            guard let next = scope.move(from: current, direction: .forward) else { return false }
            storage.focusedValue = next
            return true
        }

        @discardableResult
        public func moveBackward(in scope: FocusScope<Value>) -> Bool {
            guard let current = storage.focusedValue, scope.contains(current) else { return false }
            guard let next = scope.move(from: current, direction: .backward) else { return false }
            storage.focusedValue = next
            return true
        }

        public func enter(_ scope: FocusScope<Value>) {
            if let first = scope.first {
                storage.focusedValue = first
            }
        }
    }
}

public struct FocusRing<Value: Hashable> {
    public enum Direction {
        case forward
        case backward
    }

    private let order: [Value]
    private let indexLookup: [Value: Int]

    public init(_ order: [Value]) {
        var unique: [Value] = []
        var seen = Set<Value>()
        for value in order where seen.insert(value).inserted {
            unique.append(value)
        }
        self.order = unique

        var lookup: [Value: Int] = [:]
        for (index, value) in unique.enumerated() {
            lookup[value] = index
        }
        self.indexLookup = lookup
    }

    public func contains(_ value: Value) -> Bool {
        indexLookup[value] != nil
    }

    public var isEmpty: Bool { order.isEmpty }

    public var first: Value? { order.first }

    public var last: Value? { order.last }

    public func move(from current: Value?, direction: Direction, wraps: Bool = true) -> Value? {
        guard !order.isEmpty else { return nil }

        guard let current = current, let currentIndex = indexLookup[current] else {
            switch direction {
            case .forward: return order.first
            case .backward: return order.last
            }
        }

        switch direction {
        case .forward:
            let nextIndex = currentIndex + 1
            if nextIndex < order.count {
                return order[nextIndex]
            }
            return wraps ? order.first : nil
        case .backward:
            let previousIndex = currentIndex - 1
            if previousIndex >= 0 {
                return order[previousIndex]
            }
            return wraps ? order.last : nil
        }
    }
}

public struct FocusScope<Value: Hashable> {
    public let ring: FocusRing<Value>
    private let forwardWraps: Bool
    private let backwardWraps: Bool

    public var first: Value? { ring.first }
    public var last: Value? { ring.last }
    public var isEmpty: Bool { ring.isEmpty }

    public init(_ order: [Value], wraps: Bool = true) {
        self.init(ring: FocusRing(order), forwardWraps: wraps, backwardWraps: wraps)
    }

    public init(
        ring: FocusRing<Value>,
        wraps: Bool = true
    ) {
        self.init(ring: ring, forwardWraps: wraps, backwardWraps: wraps)
    }

    public init(
        ring: FocusRing<Value>,
        forwardWraps: Bool,
        backwardWraps: Bool
    ) {
        self.ring = ring
        self.forwardWraps = forwardWraps
        self.backwardWraps = backwardWraps
    }

    public init(
        _ order: [Value],
        forwardWraps: Bool,
        backwardWraps: Bool
    ) {
        self.init(
            ring: FocusRing(order),
            forwardWraps: forwardWraps,
            backwardWraps: backwardWraps
        )
    }

    public func contains(_ value: Value) -> Bool {
        ring.contains(value)
    }

    fileprivate func move(from current: Value, direction: FocusRing<Value>.Direction) -> Value? {
        switch direction {
        case .forward:
            return ring.move(from: current, direction: .forward, wraps: forwardWraps)
        case .backward:
            return ring.move(from: current, direction: .backward, wraps: backwardWraps)
        }
    }
}
