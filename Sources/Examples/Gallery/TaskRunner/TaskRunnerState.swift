import Foundation
import SwifTeaCore
import SwifTeaUI

struct TaskRunnerState {
    struct Step: Identifiable, Equatable {
        struct Run: Equatable {
            var remaining: TimeInterval
            let total: TimeInterval

            var progress: Double {
                guard total > 0 else { return 1 }
                return min(1, max(0, (total - remaining) / total))
            }

            static let minimumDuration: TimeInterval = 0.1
        }

        enum Status: Equatable {
            enum Result: Equatable {
                case success
                case failure
            }

            case pending
            case running(Run)
            case completed(Result)
        }

        let id: UUID
        var title: String
        var duration: TimeInterval
        var status: Status

        init(
            id: UUID = UUID(),
            title: String,
            duration: TimeInterval,
            status: Status = .pending
        ) {
            self.id = id
            self.title = title
            self.duration = duration
            self.status = status
        }

        static func defaults() -> [Step] {
            [
                Step(title: "Fetch configuration", duration: 4.0),
                Step(title: "Run analysis", duration: 5.5),
                Step(title: "Write summary", duration: 3.5),
                Step(title: "Publish artifacts", duration: 4.5),
                Step(title: "Notify subscribers", duration: 2.5)
            ]
        }
    }

    var steps: [Step]
    var toastQueue = StatusToastQueue(maxCount: 3, defaultTTL: 6)
    var focusedIndex: Int
    var selectedIndices: Set<Int>
    var terminalMetrics: TerminalMetrics

    private var toastTimeAccumulator: TimeInterval
    private let toastTickIntervalValue: TimeInterval = 0.5

    init(
        steps: [Step] = Step.defaults(),
        focusedIndex: Int = 0,
        selectedIndices: Set<Int> = [],
        toastTimeAccumulator: TimeInterval = 0,
        terminalMetrics: TerminalMetrics = TerminalMetrics.current()
    ) {
        self.steps = steps
        self.focusedIndex = steps.isEmpty ? -1 : max(0, min(focusedIndex, steps.count - 1))
        self.selectedIndices = selectedIndices
        self.toastTimeAccumulator = toastTimeAccumulator
        self.terminalMetrics = terminalMetrics
    }
}

extension TaskRunnerState {
    var runningIndices: [Int] {
        steps.indices.filter { index in
            if case .running = steps[index].status { return true }
            return false
        }
    }

    var completedCount: Int {
        steps.reduce(0) { partial, step in
            if case .completed = step.status { return partial + 1 }
            return partial
        }
    }

    var totalCount: Int { steps.count }

    var isComplete: Bool {
        guard totalCount > 0 else { return false }
        return steps.allSatisfy { step in
            if case .completed = step.status { return true }
            return false
        }
    }

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        let completed = steps.reduce(0.0) { sum, step in
            switch step.status {
            case .pending:
                return sum
            case .running(let run):
                return sum + run.progress
            case .completed:
                return sum + 1
            }
        }
        return min(1, max(0, completed / Double(totalCount)))
    }

    var activeToast: StatusToast? {
        toastQueue.activeToast
    }

    func isSelected(_ index: Int) -> Bool {
        selectedIndices.contains(index)
    }

    func selectionCount() -> Int {
        selectedIndices.count
    }

    mutating func tickToasts(deltaTime: TimeInterval) {
        guard deltaTime > 0 else { return }
        toastTimeAccumulator += deltaTime
        while toastTimeAccumulator >= toastTickIntervalValue {
            toastTimeAccumulator -= toastTickIntervalValue
            toastQueue.tick()
        }
    }

    mutating func clearToasts() {
        toastQueue.clear()
        toastTimeAccumulator = 0
    }

    mutating func enqueueToast(
        _ text: String,
        color: ANSIColor,
        ttl: Int? = nil,
        atFront: Bool = true
    ) {
        toastQueue.enqueue(text, color: color, ttl: ttl, atFront: atFront)
    }

    var toastTickInterval: TimeInterval {
        toastTickIntervalValue
    }

    mutating func updateTerminalMetrics(_ metrics: TerminalMetrics) {
        terminalMetrics = metrics
    }

    var isCompactLayout: Bool {
        terminalMetrics.horizontalSizeClass == .compact || terminalMetrics.size.columns < 95
    }

    var statusMeterWidth: Int {
        isCompactLayout ? 14 : 20
    }

    var stepMeterWidth: Int {
        isCompactLayout ? 10 : 12
    }
}
