import Foundation
import SwifTeaCore

struct TaskRunnerViewModel {
    func moveFocus(offset: Int, state: inout TaskRunnerState) {
        guard !state.steps.isEmpty, offset != 0 else { return }
        let count = state.steps.count
        let current = state.focusedIndex >= 0 ? state.focusedIndex : 0
        let normalizedOffset = ((offset % count) + count) % count
        let next = (current + normalizedOffset) % count
        state.focusedIndex = next
    }

    func toggleSelection(state: inout TaskRunnerState) {
        guard state.steps.indices.contains(state.focusedIndex) else { return }
        if state.selectedIndices.contains(state.focusedIndex) {
            state.selectedIndices.remove(state.focusedIndex)
        } else {
            state.selectedIndices.insert(state.focusedIndex)
        }
    }

    func selectAll(state: inout TaskRunnerState) {
        state.selectedIndices = Set(state.steps.indices)
    }

    func clearSelection(state: inout TaskRunnerState) {
        state.selectedIndices.removeAll()
    }

    func startSelected(state: inout TaskRunnerState) {
        let targets = selectionOrFocus(state: state)
        guard !targets.isEmpty else { return }

        var started: [Int] = []
        for index in targets {
            guard state.steps.indices.contains(index) else { continue }
            guard case .pending = state.steps[index].status else { continue }
            let duration = max(TaskRunnerState.Step.Run.minimumDuration, max(0, state.steps[index].duration))
            let run = TaskRunnerState.Step.Run(remaining: duration, total: duration)
            state.steps[index].status = .running(run)
            state.enqueueToast("Started \(state.steps[index].title)", color: .cyan, atFront: true)
            started.append(index)
        }

        if !started.isEmpty {
            state.selectedIndices.subtract(Set(started))
        }
    }

    func markFailure(state: inout TaskRunnerState) -> [UUID] {
        let targets = selectionOrFocus(state: state)
        guard !targets.isEmpty else { return [] }
        var failedAny = false
        var cancelled: [UUID] = []

        for index in targets {
            guard state.steps.indices.contains(index) else { continue }
            guard case .running = state.steps[index].status else { continue }
            failedAny = true
            let title = state.steps[index].title
            cancelled.append(state.steps[index].id)
            state.steps[index].status = .completed(.failure)
            state.enqueueToast("Failed \(title)", color: .yellow)
        }

        if failedAny {
            state.selectedIndices.subtract(Set(targets))
        }

        return cancelled
    }

    func tickToasts(state: inout TaskRunnerState, interval: TimeInterval) {
        state.tickToasts(deltaTime: interval)
    }

    func reset(state: inout TaskRunnerState) {
        for index in state.steps.indices {
            state.steps[index].status = .pending
        }
        state.selectedIndices.removeAll()
        state.focusedIndex = state.steps.isEmpty ? -1 : 0
        state.clearToasts()
        state.enqueueToast("Progress reset", color: .yellow)
    }

    func updateProgress(
        id: UUID,
        remaining: TimeInterval,
        total: TimeInterval,
        state: inout TaskRunnerState
    ) {
        guard let index = state.steps.firstIndex(where: { $0.id == id }) else { return }
        guard case .running(var run) = state.steps[index].status else { return }
        let effectiveTotal = max(run.total, total)
        run.remaining = max(0, min(effectiveTotal, remaining))
        state.steps[index].status = .running(run)
    }

    func finishStep(
        id: UUID,
        result: TaskRunnerState.Step.Status.Result,
        state: inout TaskRunnerState
    ) {
        guard let index = state.steps.firstIndex(where: { $0.id == id }) else { return }
        state.steps[index].status = .completed(result)
        let title = state.steps[index].title
        let color: ANSIColor = (result == .success) ? .green : .yellow
        let verb = (result == .success) ? "Completed" : "Failed"
        state.enqueueToast("\(verb) \(title)", color: color)
        if result == .success && state.isComplete {
            state.enqueueToast("All tasks complete", color: .green)
        }
    }

    private func selectionOrFocus(state: TaskRunnerState) -> [Int] {
        if !state.selectedIndices.isEmpty {
            return state.selectedIndices.sorted()
        }
        guard state.steps.indices.contains(state.focusedIndex) else { return [] }
        return [state.focusedIndex]
    }
}
