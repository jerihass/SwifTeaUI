import Testing
@testable import SwifTeaCore
@testable import SwifTeaUI

struct StatusToastQueueTests {

    @Test("Queue enqueues at front and respects max count")
    func testEnqueueCapacity() {
        var queue = StatusToastQueue(maxCount: 2, defaultTTL: 3)
        queue.enqueue("First", color: .yellow, atFront: true)
        queue.enqueue("Second", color: .green, atFront: true)
        queue.enqueue("Third", color: .cyan, atFront: true)

        #expect(queue.allToasts.count == 2)
        #expect(queue.activeToast?.text == "Third")
        #expect(queue.allToasts.last?.text == "Second")
    }

    @Test("Tick removes expired toasts")
    func testTickingRemovesExpired() {
        var queue = StatusToastQueue(maxCount: 3, defaultTTL: 2)
        queue.enqueue("Short", color: .yellow, ttl: 1)
        queue.enqueue("Longer", color: .green, ttl: 3, atFront: false)

        queue.tick()
        #expect(queue.allToasts.count == 1)
        #expect(queue.activeToast?.text == "Longer")

        queue.tick()
        queue.tick()
        #expect(queue.isEmpty)
    }
}
