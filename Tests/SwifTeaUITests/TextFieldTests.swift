import SnapshotTestSupport
import Testing
@testable import SwifTeaUI
@testable import SwifTeaUI

private extension String {
    func strippingANSI() -> String {
        var result = ""
        var iterator = makeIterator()
        var inEscape = false

        while let character = iterator.next() {
            if inEscape {
                if ("a"..."z").contains(character) || ("A"..."Z").contains(character) {
                    inEscape = false
                }
                continue
            }

            if character == "\u{001B}" {
                inEscape = true
                continue
            }

            result.append(character)
        }

        return result
    }

    @Test("Text editor reports cursor line index")
    func testTextEditorReportsCursorLine() {
        final class EditorHarness {
            @State var text = "Hello\nWorld"
            var textBinding: Binding<String> { $text }
        }

        let harness = EditorHarness()
        var cursorPosition = 7 // inside second line
        var cursorLine = -1

        let positionBinding = Binding<Int>(
            get: { cursorPosition },
            set: { cursorPosition = $0 }
        )
        let lineBinding = Binding<Int>(
            get: { cursorLine },
            set: { cursorLine = $0 }
        )

        let editor = TextEditor(text: harness.textBinding, cursorPosition: positionBinding)
            .cursorLine(lineBinding)

        _ = editor.render()
        #expect(cursorLine == 2)
    }
}

struct TextFieldTests {

    private struct Harness {
        @State var value = ""
        var binding: Binding<String> { $value }
    }

    @Test("Custom focus style overrides default styling")
    func testCustomFocusStyle() {
        let harness = Harness()
        let binding = harness.binding
        let customStyle = FocusStyle(indicator: "*", color: .green, bold: false)
        let field = TextField("Prompt", text: binding, cursor: "|", focusStyle: customStyle)

        #expect(field.render().contains("*"))
        #expect(field.render().contains(ANSIColor.green.rawValue))
    }

    @Test("Text input binding supports character insertion and backspace")
    func testApplyEdits() {
        let harness = Harness()
        let binding = harness.binding

        binding.apply(.insert("A"))
        binding.apply(.insert("b"))
        #expect(harness.value == "Ab")

        binding.apply(.backspace)
        #expect(harness.value == "A")
    }

    @Test("Text field renders current value with cursor when focused")
    func testRenderMirrorsBinding() {
        let harness = Harness()
        let binding = harness.binding
        var cursor = 0
        let cursorBinding = Binding<Int>(
            get: { cursor },
            set: { cursor = $0 }
        )
        let field = TextField("Prompt", text: binding, cursor: "|", cursorPosition: cursorBinding)

        let rendered = field.render()
        #expect(
            rendered.contains("\u{001B}[7m")
            || rendered.contains("\u{001B}[4m")
            || rendered.contains("|")
        )

        binding.apply(.insert("X"))
        let renderedX = field.render()
        #expect(renderedX.contains("X"))
        #expect(cursorBinding.wrappedValue == 0)
    }

    @Test("Text field removes cursor when focus binding is false")
    func testRenderWithoutFocus() {
        let harness = Harness()
        let binding = harness.binding
        var isFocused = false
        let focus = Binding<Bool>(
            get: { isFocused },
            set: { isFocused = $0 }
        )

        let field = TextField("Placeholder", text: binding, cursor: "|")
            .focused(focus)
        #expect(field.render().strippingANSI() == "Placeholder")

        isFocused = true
        let rendered = field.render().strippingANSI()
        #expect(rendered == "Placeholder" || rendered.contains("|"))
    }

    @Test("Text editor renders cursor within the line when cursor binding provided")
    func testTextEditorCursorPosition() {
        final class EditorHarness {
            @State var text = "Hello"
            var textBinding: Binding<String> { $text }
        }

        let harness = EditorHarness()
        var cursorPosition = 2
        let cursorBinding = Binding<Int>(
            get: { cursorPosition },
            set: { cursorPosition = $0 }
        )

        let editor = TextEditor(text: harness.textBinding, cursorPosition: cursorBinding)
        let rendered = editor.render()
        #expect(
            rendered.contains("He█llo")
            || rendered.contains("He▌llo")
            || rendered.contains("\u{001B}[7ml\u{001B}[0m")
        )
        #expect(cursorPosition == 2)
    }

    @Test("Key events map to text field events")
    func testEventMapping() {
        #expect(textFieldEvent(from: .char("a")) == .insert("a"))
        #expect(textFieldEvent(from: .backspace) == .backspace)
        #expect(textFieldEvent(from: .enter) == .submit)
        #expect(textFieldEvent(from: .leftArrow) == .moveCursor(-1))
        #expect(textFieldEvent(from: .rightArrow) == .moveCursor(1))
    }

    @Test("Focus bindings toggle wrapped focus value")
    func testFocusStateBinding() {
        struct FocusHarness {
            enum Field: Hashable { case note }
            @FocusState var field: Field?
        }

        let harness = FocusHarness()
        let focusBinding = harness.$field.isFocused(.note)

        #expect(harness.field == nil)
        #expect(focusBinding.wrappedValue == false)

        focusBinding.wrappedValue = true
        #expect(harness.field == .note)

        focusBinding.wrappedValue = false
        #expect(harness.field == nil)
    }

    @Test("Focus ring cycles forward and backward")
    func testFocusRingMovement() {
        enum Field: Hashable { case controls, note, log }
        let ring = FocusRing<Field>([.controls, .note, .log])

        #expect(ring.move(from: nil, direction: .forward) == .controls)
        #expect(ring.move(from: nil, direction: .backward) == .log)
        #expect(ring.move(from: .controls, direction: .forward) == .note)
        #expect(ring.move(from: .controls, direction: .backward) == .log)
        #expect(ring.move(from: .log, direction: .forward) == .controls)
    }

    @Test("Projected focus state moves using focus ring helpers")
    func testFocusProjectedMoves() {
        struct FocusHarness {
            enum Field: Hashable { case controls, note }
            @FocusState var field: Field?
        }

        let harness = FocusHarness()
        let ring = FocusRing<FocusHarness.Field>([.controls, .note])

        harness.$field.moveForward(in: ring)
        #expect(harness.field == .controls)

        harness.$field.moveForward(in: ring)
        #expect(harness.field == .note)

        harness.$field.moveBackward(in: ring)
        #expect(harness.field == .controls)
    }

    @Test("Focus scope stops at boundaries when wrapping disabled")
    func testFocusScopeBoundaries() {
        struct FocusHarness {
            enum Field: Hashable { case controls, title, body }
            @FocusState var field: Field?
        }

        var harness = FocusHarness()
        harness.field = .title

        let scope = FocusScope<FocusHarness.Field>(
            [.title, .body],
            forwardWraps: false,
            backwardWraps: false
        )

        let firstAdvanceHandled = harness.$field.moveForward(in: scope)
        #expect(firstAdvanceHandled)
        #expect(harness.field == .body)

        let secondAdvanceHandled = harness.$field.moveForward(in: scope)
        #expect(!secondAdvanceHandled)
        #expect(harness.field == .body)

        let backwardHandled = harness.$field.moveBackward(in: scope)
        #expect(backwardHandled)
        #expect(harness.field == .title)

        let exitHandled = harness.$field.moveBackward(in: scope)
        #expect(!exitHandled)
        #expect(harness.field == .title)
    }

    @Test("Blinking cursor toggles visibility based on cursor blinker")
    func testBlinkingCursorBehavior() {
        SnapshotSync.cursorBlinkerLock.withLock {
            let previousBlinker = CursorBlinker.shared
            defer { CursorBlinker.shared = previousBlinker }

            var blinker = CursorBlinker.shared
            blinker.isEnabled = true
            blinker.forcedVisibility = nil
            blinker.timeProvider = { 0 }
            CursorBlinker.shared = blinker

            let harness = Harness()
            let field = TextField("Prompt", text: harness.binding, cursor: "▌")
                .blinkingCursor()
                .focusRingStyle(FocusStyle(indicator: "", color: .cyan, bold: false))

            let visible = field.render()
            #expect(visible.contains("\u{001B}[7m") || visible.contains("\u{001B}[4m") || visible.contains("▌"))

            let hiddenInterval = CursorBlinker.shared.interval
            blinker = CursorBlinker.shared
            blinker.timeProvider = { hiddenInterval }
            CursorBlinker.shared = blinker

            let hidden = field.render().strippingANSI()
            #expect(hidden == "Prompt")
        }
    }
}
