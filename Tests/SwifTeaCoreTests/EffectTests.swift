import Foundation
import Testing
@testable import SwifTeaUI

struct EffectTests {
    enum TestAction {
        case ping
    }

    @Test("Effect timer emits repeated actions until cancelled")
    func timerEmitsActions() async {
        let effect = Effect<TestAction>.timer(every: 0.01, repeats: true) { .ping }

        let buffer = ActionBuffer<TestAction>()
        let task = Task {
            await effect.run { action in
                buffer.append(action)
            }
        }

        try? await Task.sleep(nanoseconds: 60_000_000)
        task.cancel()
        _ = await task.result

        let emissions = buffer.snapshot()
        #expect(emissions.count >= 2)
    }
}

final class ActionBuffer<Action: Sendable>: @unchecked Sendable {
    private var values: [Action] = []
    private let lock = NSLock()

    func append(_ value: Action) {
        lock.lock()
        values.append(value)
        lock.unlock()
    }

    func snapshot() -> [Action] {
        lock.lock()
        let snapshot = values
        lock.unlock()
        return snapshot
    }
}
