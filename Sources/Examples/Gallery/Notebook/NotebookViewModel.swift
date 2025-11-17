import Foundation
import SwifTeaUI

struct NotebookViewModel {
    enum Effect {
        case focus(NotebookFocusField?)
    }

    func selectNext(state: inout NotebookState) {
        guard !state.notes.isEmpty else { return }
        state.selectedIndex = (state.selectedIndex + 1) % state.notes.count
        loadEditor(from: &state)
    }

    func selectPrevious(state: inout NotebookState) {
        guard !state.notes.isEmpty else { return }
        state.selectedIndex = (state.selectedIndex - 1 + state.notes.count) % state.notes.count
        loadEditor(from: &state)
    }

    func handleTitle(event: TextFieldEvent, state: inout NotebookState) -> Effect? {
        switch event {
        case .insert(let character):
            state.editorTitle.append(character)
            syncTitle(into: &state)
            return nil

        case .backspace:
            if !state.editorTitle.isEmpty {
                state.editorTitle.removeLast()
                syncTitle(into: &state)
            }
            return nil

        case .submit:
            return .focus(.editorBody)
        }
    }

    func handleBody(event: TextFieldEvent, state: inout NotebookState) -> Effect? {
        switch event {
        case .insert(let character):
            insertCharacter(character, in: &state)
            syncBody(into: &state)
            return nil

        case .backspace:
            removeCharacter(in: &state)
            syncBody(into: &state)
            return nil

        case .submit:
            syncBody(into: &state)
            state.statusMessage = "Saved \"\(state.editorTitle)\" at \(Self.timestampFormatter.string(from: Date()))"
            return .focus(.sidebar)
        }
    }

    // MARK: - Helpers

    private func loadEditor(from state: inout NotebookState) {
        guard state.notes.indices.contains(state.selectedIndex) else { return }
        let note = state.notes[state.selectedIndex]
        state.editorTitle = note.title
        state.editorBody = note.body
        state.editorBodyCursor = note.body.count
    }

    private func syncTitle(into state: inout NotebookState) {
        guard state.notes.indices.contains(state.selectedIndex) else { return }
        state.notes[state.selectedIndex].title = state.editorTitle
    }

    private func syncBody(into state: inout NotebookState) {
        guard state.notes.indices.contains(state.selectedIndex) else { return }
        state.notes[state.selectedIndex].body = state.editorBody
    }

    private func insertCharacter(_ character: Character, in state: inout NotebookState) {
        let cursor = clampCursor(state.editorBodyCursor, within: state.editorBody)
        let index = state.editorBody.index(state.editorBody.startIndex, offsetBy: cursor)
        state.editorBody.insert(character, at: index)
        state.editorBodyCursor = cursor + 1
    }

    private func removeCharacter(in state: inout NotebookState) {
        let cursor = clampCursor(state.editorBodyCursor, within: state.editorBody)
        guard cursor > 0 else { return }
        let removalIndex = state.editorBody.index(state.editorBody.startIndex, offsetBy: cursor - 1)
        state.editorBody.remove(at: removalIndex)
        state.editorBodyCursor = cursor - 1
    }

    private func clampCursor(_ cursor: Int, within text: String) -> Int {
        max(0, min(cursor, text.count))
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
