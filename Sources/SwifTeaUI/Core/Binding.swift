public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getter = get
        self.setter = set
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public func update(_ transform: (inout Value) -> Void) {
        var value = getter()
        transform(&value)
        setter(value)
    }
}

public extension Binding {
    func map<Subject>(_ keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> {
        Binding<Subject>(
            get: {
                self.wrappedValue[keyPath: keyPath]
            },
            set: { newValue in
                self.update { value in
                    value[keyPath: keyPath] = newValue
                }
            }
        )
    }

    static func constant(_ value: Value) -> Binding<Value> {
        Binding<Value>(
            get: { value },
            set: { _ in }
        )
    }
}
