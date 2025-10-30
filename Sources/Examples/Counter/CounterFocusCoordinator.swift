import SwifTeaCore

struct CounterFocusCoordinator {
    private let globalRing = FocusRing<CounterFocusField>([
        .controls,
        .noteTitle,
        .noteBody
    ])

    private let noteScope = FocusScope<CounterFocusField>(
        [.noteTitle, .noteBody],
        forwardWraps: false,
        backwardWraps: false
    )

    func focusNext(current: inout CounterFocusField?) {
        if let currentField = current,
           noteScope.contains(currentField),
           let next = noteScope.ring.move(from: currentField, direction: .forward, wraps: false) {
            current = next
            return
        }

        if let next = globalRing.move(from: current, direction: .forward) {
            current = next
        } else if current == nil {
            current = globalRing.first
        }
    }

    func focusPrevious(current: inout CounterFocusField?) {
        if let currentField = current,
           noteScope.contains(currentField),
           let previous = noteScope.ring.move(from: currentField, direction: .backward, wraps: false) {
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
