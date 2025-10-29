@propertyWrapper
public struct State<Value> {
    final class Storage {
        var value: Value
        init(_ value: Value) { self.value = value }
    }

    private var storage: Storage

    public init(wrappedValue: Value) {
        self.storage = Storage(wrappedValue)
    }

    public var wrappedValue: Value {
        get { storage.value }
        mutating set { storage.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.value },
            set: { storage.value = $0 }
        )
    }
}
