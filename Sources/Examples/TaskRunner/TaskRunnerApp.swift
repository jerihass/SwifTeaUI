import Foundation
import SwifTeaCore
import SwifTeaUI

public struct TaskRunnerApp: TUIApp {
    public init() {}
    public static var framesPerSecond: Int { 30 }
    public var body: some TUIScene { TaskRunnerScene() }
}

struct TaskRunnerScene: TUIScene {
    typealias Model = TaskRunnerModel
    typealias Action = TaskRunnerModel.Action

    var model: TaskRunnerModel

    init(model: TaskRunnerModel = TaskRunnerModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: TaskRunnerModel) -> some TUIView {
        model.makeView()
    }

    mutating func initializeEffects() {
        model.initializeEffects()
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        self.model.mapKeyToAction(key)
    }

    func shouldExit(for action: Action) -> Bool {
        model.shouldExit(for: action)
    }

    mutating func handleTerminalResize(from oldSize: TerminalSize, to newSize: TerminalSize) {
        model.updateTerminalMetrics(TerminalMetrics(size: newSize))
    }
}

struct TaskRunnerModel {
    enum Action {
        case startSelected
        case toggleSelection
        case selectAll
        case clearSelection
        case moveFocus(Int)
        case failSelected
        case reset
        case quit
        case toastTick
        case stepProgress(id: UUID, remaining: TimeInterval, total: TimeInterval)
        case stepCompleted(id: UUID, result: TaskRunnerState.Step.Status.Result)
    }

    @State private var state: TaskRunnerState
    private let viewModel: TaskRunnerViewModel
    private var activeStepEffects: Set<UUID> = []
    private static let toastTimerID = "TaskRunner.toastTimer"
    private static let progressTick: TimeInterval = TaskRunnerState.Step.Run.minimumDuration

    init(
        state: TaskRunnerState = TaskRunnerState(),
        viewModel: TaskRunnerViewModel = TaskRunnerViewModel()
    ) {
        self._state = State(wrappedValue: state)
        self.viewModel = viewModel
    }

    mutating func initializeEffects() {
        SwifTea.dispatch(
            Effect<Action>.timer(
                every: state.toastTickInterval,
                initialDelay: state.toastTickInterval,
                repeats: true
            ) { .toastTick },
            id: Self.toastTimerID,
            cancelExisting: true
        )
    }

    mutating func update(action: Action) {
        switch action {
        case .startSelected:
            viewModel.startSelected(state: &state)
            startEffectsForRunningSteps()
        case .toggleSelection:
            viewModel.toggleSelection(state: &state)
        case .selectAll:
            viewModel.selectAll(state: &state)
        case .clearSelection:
            viewModel.clearSelection(state: &state)
        case .moveFocus(let offset):
            viewModel.moveFocus(offset: offset, state: &state)
        case .failSelected:
            let canceled = viewModel.markFailure(state: &state)
            cancelEffects(for: canceled)
        case .reset:
            viewModel.reset(state: &state)
            cancelAllStepEffects()
        case .toastTick:
            viewModel.tickToasts(state: &state, interval: state.toastTickInterval)
        case .stepProgress(let id, let remaining, let total):
            viewModel.updateProgress(id: id, remaining: remaining, total: total, state: &state)
        case .stepCompleted(let id, let result):
            viewModel.finishStep(id: id, result: result, state: &state)
            activeStepEffects.remove(id)
        case .quit:
            break
        }
    }

    func makeView() -> some TUIView {
        TaskRunnerView(state: state)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .enter:
            return .startSelected
        case .char(" "):
            return .toggleSelection
        case .char("a"), .char("A"):
            return .selectAll
        case .char("c"), .char("C"):
            return .clearSelection
        case .char("f"), .char("F"):
            return .failSelected
        case .char("r"), .char("R"):
            return .reset
        case .upArrow:
            return .moveFocus(-1)
        case .downArrow:
            return .moveFocus(1)
        case .char("q"), .char("Q"), .ctrlC, .escape:
            return .quit
        default:
            return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        if case .quit = action {
            return true
        }
        return false
    }

    func stepID(at index: Int) -> UUID? {
        guard state.steps.indices.contains(index) else { return nil }
        return state.steps[index].id
    }

    mutating func updateTerminalMetrics(_ metrics: TerminalMetrics) {
        state.updateTerminalMetrics(metrics)
    }

    private mutating func startEffectsForRunningSteps() {
        for step in state.steps {
            guard case .running(let run) = step.status else { continue }
            guard !activeStepEffects.contains(step.id) else { continue }
            activeStepEffects.insert(step.id)
            let effect = makeStepEffect(for: step, run: run)
            SwifTea.dispatch(effect, id: step.id, cancelExisting: true)
        }
    }

    private mutating func cancelEffects(for ids: [UUID]) {
        guard !ids.isEmpty else { return }
        for id in ids {
            if activeStepEffects.contains(id) {
                SwifTea.cancelEffects(withID: id)
                activeStepEffects.remove(id)
            }
        }
    }

    private mutating func cancelAllStepEffects() {
        for id in activeStepEffects {
            SwifTea.cancelEffects(withID: id)
        }
        activeStepEffects.removeAll()
    }

    private func makeStepEffect(
        for step: TaskRunnerState.Step,
        run: TaskRunnerState.Step.Run
    ) -> Effect<Action> {
        let total = max(Self.progressTick, run.total)
        return Effect<Action>.run { send in
            var remaining = total
            while remaining > 0 {
                let slice = min(Self.progressTick, remaining)
                try await Task.sleep(nanoseconds: slice.nanosecondsClamped())
                if Task.isCancelled { return }
                remaining = max(0, remaining - slice)
                send(.stepProgress(id: step.id, remaining: remaining, total: total))
            }
            send(.stepCompleted(id: step.id, result: .success))
        }
    }
}

private extension TimeInterval {
    func nanosecondsClamped() -> UInt64 {
        if self.isNaN || self <= 0 {
            return 0
        }
        let capped = min(self, TimeInterval(UInt64.max) / 1_000_000_000)
        return UInt64(capped * 1_000_000_000)
    }
}
