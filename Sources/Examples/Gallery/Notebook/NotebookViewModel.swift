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
            insertCharacter(character, in: &state.editorTitle, cursor: &state.editorTitleCursor)
            syncTitle(into: &state)
            return nil

        case .backspace:
            removeCharacter(in: &state.editorTitle, cursor: &state.editorTitleCursor)
            syncTitle(into: &state)
            return nil

        case .submit:
            return .focus(.editorBody)

        case .moveCursor(let delta):
            state.editorTitleCursor = clampCursor(state.editorTitleCursor + delta, within: state.editorTitle)
            return nil
        }
    }

    func handleBody(event: TextFieldEvent, state: inout NotebookState) -> Effect? {
        switch event {
        case .insert(let character):
            insertCharacter(character, in: &state.editorBody, cursor: &state.editorBodyCursor)
            syncBody(into: &state)
            return nil

        case .backspace:
            removeCharacter(in: &state.editorBody, cursor: &state.editorBodyCursor)
            syncBody(into: &state)
            return nil

        case .submit:
            syncBody(into: &state)
            state.statusMessage = "Saved \"\(state.editorTitle)\" at \(Self.timestampFormatter.string(from: Date()))"
            return .focus(.sidebar)

        case .moveCursor(let delta):
            state.editorBodyCursor = clampCursor(state.editorBodyCursor + delta, within: state.editorBody)
            return nil
        }
    }

    // MARK: - Helpers

    private func loadEditor(from state: inout NotebookState) {
        guard state.notes.indices.contains(state.selectedIndex) else { return }
        let note = state.notes[state.selectedIndex]
        state.editorTitle = note.title
        state.editorBody = note.body
        state.editorTitleCursor = note.title.count
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

    private func insertCharacter(_ character: Character, in text: inout String, cursor: inout Int) {
        let clamped = clampCursor(cursor, within: text)
        let index = text.index(text.startIndex, offsetBy: clamped)
        text.insert(character, at: index)
        cursor = clamped + 1
    }

    private func removeCharacter(in text: inout String, cursor: inout Int) {
        let clamped = clampCursor(cursor, within: text)
        guard clamped > 0 else { return }
        let removalIndex = text.index(text.startIndex, offsetBy: clamped - 1)
        text.remove(at: removalIndex)
        cursor = clamped - 1
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
