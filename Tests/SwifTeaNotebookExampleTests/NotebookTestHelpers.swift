import SnapshotTestSupport
import SwifTeaCore
import SwifTeaUI
@testable import NotebookExample

let defaultSnapshotSize = TerminalSize(columns: 140, rows: 40)

func renderNotebook(
    _ app: NotebookScene,
    size: TerminalSize = defaultSnapshotSize
) -> String {
    return SnapshotSync.cursorBlinkerLock.withLock {
        var blinker = CursorBlinker.shared
        let previousForcedVisibility = blinker.forcedVisibility
        blinker.forcedVisibility = true
        CursorBlinker.shared = blinker
        defer {
            var resetBlinker = CursorBlinker.shared
            resetBlinker.forcedVisibility = previousForcedVisibility
            CursorBlinker.shared = resetBlinker
        }

        return TerminalDimensions.withTemporarySize(size) {
            app.view(model: app.model).render()
        }
    }
}
