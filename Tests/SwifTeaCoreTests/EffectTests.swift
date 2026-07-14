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
        let (emissions, continuation) = AsyncStream<TestAction>.makeStream()

        let task = Task {
            await effect.run { action in
                continuation.yield(action)
            }
            continuation.finish()
        }

        let emittedRepeatedly = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = emissions.makeAsyncIterator()
                guard await iterator.next() != nil else { return false }
                guard await iterator.next() != nil else { return false }
                return true
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return false
            }

            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }

        task.cancel()
        _ = await task.result
        continuation.finish()

        #expect(emittedRepeatedly)
    }
}
