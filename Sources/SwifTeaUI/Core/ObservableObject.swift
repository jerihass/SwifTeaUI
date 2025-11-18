public final class ObservableObjectPublisher {
    public init() {}
    public func send() {}
}

public protocol ObservableObject: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

@propertyWrapper
public struct StateObject<ObjectType: ObservableObject> {
    final class Storage {
        var object: ObjectType
        init(_ object: ObjectType) {
            self.object = object
        }
    }

    private var storage: Storage

    public init(wrappedValue builder: @autoclosure () -> ObjectType) {
        self.storage = Storage(builder())
    }

    public var wrappedValue: ObjectType {
        get { storage.object }
        nonmutating set { storage.object = newValue }
    }

    public var projectedValue: ObservedObject<ObjectType> {
        ObservedObject(wrappedValue: wrappedValue)
    }
}

@propertyWrapper
public struct ObservedObject<ObjectType: ObservableObject> {
    public var wrappedValue: ObjectType

    public init(wrappedValue: ObjectType) {
        self.wrappedValue = wrappedValue
    }

    public var projectedValue: ObjectType {
        wrappedValue
    }
}
