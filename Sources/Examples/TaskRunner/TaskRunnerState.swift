import SwifTeaCore
import SwifTeaUI

struct TaskRunnerState {
    struct Step: Equatable {
        enum Status: Equatable {
            enum Result: Equatable {
                case success
                case failure
            }

            case pending
            case running
            case completed(Result)
        }

        var title: String
        var status: Status
    }

    var steps: [Step] = [
        Step(title: "Fetch configuration", status: .pending),
        Step(title: "Run analysis", status: .pending),
        Step(title: "Write summary", status: .pending),
        Step(title: "Publish artifacts", status: .pending)
    ]

    var toastQueue = StatusToastQueue(maxCount: 3, defaultTTL: 6)
}

extension TaskRunnerState {
    var activeIndex: Int? {
        steps.firstIndex { step in
            if case .running = step.status { return true }
            return false
        }
    }

    var activeStep: Step? {
        activeIndex.map { steps[$0] }
    }

    var completedCount: Int {
        steps.reduce(into: 0) { count, step in
            if case .completed = step.status {
                count += 1
            }
        }
    }

    var totalCount: Int {
        steps.count
    }

    var isComplete: Bool {
        completedCount == totalCount && totalCount > 0
    }

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    mutating func tickToasts() {
        toastQueue.tick()
    }

    mutating func clearToasts() {
        toastQueue.clear()
    }

    var activeToast: StatusToast? {
        toastQueue.activeToast
    }

    mutating func enqueueToast(
        _ text: String,
        color: ANSIColor,
        ttl: Int? = nil,
        atFront: Bool = true
    ) {
        toastQueue.enqueue(text, color: color, ttl: ttl, atFront: atFront)
    }
}
