import Testing
@testable import SwifTeaCore
@testable import SwifTeaUI

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
        let field = TextField("Prompt", text: binding, isFocused: true, cursor: "|")

        #expect(field.render() == "Prompt|")

        binding.apply(.insert("X"))
        #expect(field.render() == "X|")
    }

    @Test("Key events map to text field events")
    func testEventMapping() {
        #expect(textFieldEvent(from: .char("a")) == .insert("a"))
        #expect(textFieldEvent(from: .backspace) == .backspace)
        #expect(textFieldEvent(from: .enter) == .submit)
        #expect(textFieldEvent(from: .leftArrow) == nil)
    }
}
