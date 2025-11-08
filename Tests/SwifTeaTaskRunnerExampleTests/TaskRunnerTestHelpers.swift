import Foundation
import SwifTeaCore
import SwifTeaUI
@testable import SwifTeaTaskRunnerExample

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
        app.view(model: app).render()
    }
}
