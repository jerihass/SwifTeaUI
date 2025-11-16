import Foundation
import SwifTeaCore
import SwifTeaUI
@testable import TaskRunnerExample

let taskRunnerSnapshotSize = TerminalSize(columns: 100, rows: 24)

func renderTaskRunner(
    _ app: TaskRunnerScene,
    size: TerminalSize = taskRunnerSnapshotSize,
    time: TimeInterval = 0
) -> String {
    let previousTimeline = SpinnerTimeline.shared
    var timeline = SpinnerTimeline.shared
    timeline.timeProvider = { time }
    SpinnerTimeline.shared = timeline
    defer { SpinnerTimeline.shared = previousTimeline }

    return TerminalDimensions.withTemporarySize(size) {
        var scene = app
        scene.model.updateTerminalMetrics(TerminalMetrics(size: size))
        return scene.view(model: scene.model).render()
    }
}
