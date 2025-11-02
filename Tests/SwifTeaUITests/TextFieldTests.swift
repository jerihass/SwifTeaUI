import Testing
@testable import SwifTeaCore
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
}

struct TextFieldTests {

    private struct Harness {
        @State var value = ""
        var binding: Binding<String> { $value }
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
        let field = TextField("Prompt", text: binding, cursor: "|")

        #expect(field.render().strippingANSI() == "Prompt|")

        binding.apply(.insert("X"))
        #expect(field.render().strippingANSI() == "X|")
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

        let field = TextField("Placeholder", text: binding, focus: focus, cursor: "|")
        #expect(field.render().strippingANSI() == "Placeholder")

        isFocused = true
        #expect(field.render().strippingANSI() == "Placeholder|")
    }

    @Test("Key events map to text field events")
    func testEventMapping() {
        #expect(textFieldEvent(from: .char("a")) == .insert("a"))
        #expect(textFieldEvent(from: .backspace) == .backspace)
        #expect(textFieldEvent(from: .enter) == .submit)
        #expect(textFieldEvent(from: .leftArrow) == nil)
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
}
