import SwifTeaCore

struct NotebookFocusCoordinator {
    private let globalRing = FocusRing<NotebookFocusField>([
        .sidebar,
        .editorTitle,
        .editorBody
    ])

    private let editorScope = FocusScope<NotebookFocusField>(
        [.editorTitle, .editorBody],
        forwardWraps: false,
        backwardWraps: false
    )

    func focusNext(current: inout NotebookFocusField?) {
        if let currentField = current,
           editorScope.contains(currentField),
           let next = editorScope.ring.move(from: currentField, direction: .forward, wraps: false) {
            current = next
            return
        }

        if let next = globalRing.move(from: current, direction: .forward) {
            current = next
        } else if current == nil {
            current = globalRing.first
        }
    }

    func focusPrevious(current: inout NotebookFocusField?) {
        if let currentField = current,
           editorScope.contains(currentField),
           let previous = editorScope.ring.move(from: currentField, direction: .backward, wraps: false) {
            current = previous
            return
        }

        if let previous = globalRing.move(from: current, direction: .backward) {
            current = previous
        } else if current == nil {
            current = globalRing.last
        }
    }
}
