import SwifTeaUI

struct CounterViewModel {
    enum Effect {
        case focus(CounterFocusField?)
    }

    func increment(state: inout CounterState) {
        state.count += 1
    }

    func decrement(state: inout CounterState) {
        state.count -= 1
    }

    func handleTitle(event: TextFieldEvent, state: inout CounterState) -> Effect? {
        switch event {
        case .insert(let character):
            state.noteTitle.append(character)
            return nil

        case .backspace:
            if !state.noteTitle.isEmpty {
                state.noteTitle.removeLast()
            }
            return nil

        case .submit:
            return .focus(.noteBody)
        }
    }

    func handleBody(event: TextFieldEvent, state: inout CounterState) -> Effect? {
        switch event {
        case .insert(let character):
            state.noteBody.append(character)
            return nil

        case .backspace:
            if !state.noteBody.isEmpty {
                state.noteBody.removeLast()
            }
            return nil

        case .submit:
            state.lastSubmittedTitle = state.noteTitle
            state.lastSubmittedBody = state.noteBody
            state.noteTitle = ""
            state.noteBody = ""
            return .focus(.controls)
        }
    }
}
