import Testing
@testable import SwifTeaUI

private final class CounterModel: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    var count: Int = 0 {
        willSet { objectWillChange.send() }
    }
}

struct ObservableObjectTests {

    @Test("StateObject retains reference across renders")
    func testStateObjectPersistence() {
        struct Harness: TUIView {
            typealias Body = Never
            @StateObject var model = CounterModel()
            func render() -> String { "Count: \(model.count)" }
            var body: Never { fatalError() }
            mutating func increment() { model.count += 1 }
        }

        var view = Harness()
        let first = view.model
        view.increment()
        let second = view.model
        #expect(first === second)
        #expect(view.render() == "Count: 1")
    }

    @Test("ObservedObject references external observable")
    func testObservedObject() {
        final class Harness: TUIView {
            typealias Body = Never
            @ObservedObject var model: CounterModel
            init(model: CounterModel) { self._model = ObservedObject(wrappedValue: model) }
            func render() -> String { "Count: \(model.count)" }
            var body: Never { fatalError() }
        }

        let shared = CounterModel()
        shared.count = 5
        let view = Harness(model: shared)
        #expect(view.render() == "Count: 5")
        shared.count = 6
        #expect(view.render() == "Count: 6")
    }
}
