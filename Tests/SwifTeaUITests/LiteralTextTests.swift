import Testing

@testable import SwifTeaUI

@Suite("Literal-safe terminal text")
struct LiteralTextTests {
    @Test("Text replaces every C0, DEL, and C1 scalar while preserving line feeds")
    func textControlScalars() {
        let authored = Self.scalarString(Self.controlScalarValues)
        let expected = Self.expectedLiteralControls(preservingLineFeeds: true)

        #expect(Text(authored).render() == expected)
        #expect(Text(authored).render().contains("\u{001B}") == false)
    }

    @Test("Styled text sanitizes content before framework presentation")
    func styledText() {
        let authored = "\u{001B}]0;owned\u{0007}"
        let rendered = Text(authored).foregroundColor(.cyan).bold().render()

        #expect(
            rendered
                == ANSIColor.cyan.rawValue + "\u{001B}[1m�]0;owned�" + ANSIColor.reset.rawValue
        )
    }

    @Test("Trusted ANSI has an explicit verbatim path")
    func trustedANSI() {
        let authored = "\u{001B}[38;5;196mframework owned\u{001B}[0m"
        #expect(Text(trustedANSI: authored).render() == authored)
    }

    @Test("Literal transformation happens before frame measurement and clipping")
    func frameClipping() {
        let rendered = Text("\u{001B}[2JX").frame(width: .fixed(4)).render()
        #expect(rendered == "�[2J")
        #expect(TerminalText.visibleWidth(of: rendered) == 4)
    }

    @Test("Rich text sanitizes all controls without mutating spans")
    func richTextControlScalars() {
        let authored = Self.scalarString(Self.controlScalarValues)
        let span = TextSpan(authored).foregroundColor(.yellow)
        let rendered = RichText(width: 200) { span }.render()

        #expect(span.content == authored)
        #expect(rendered.strippingANSI() == Self.expectedLiteralControls(preservingLineFeeds: true))
        #expect(rendered.contains("\u{001B}]0;") == false)
    }

    @Test("Styled multiline spans wrap only literal-safe content")
    func styledMultilineSpans() {
        let rendered = RichText(width: 4) {
            TextSpan("A\u{001B}B\nC\u{009B}D").bold()
        }.render()

        #expect(rendered.strippingANSI() == "A�B\nC�D")
        #expect(
            rendered.split(separator: "\n", omittingEmptySubsequences: false).allSatisfy {
                TerminalText.visibleWidth(of: String($0)) <= 4
            }
        )
    }

    @Test("Text fields are single-line literal views and preserve their binding")
    func textFieldBinding() {
        let authored = "A\n\u{001B}\u{007F}\u{0080}Z"
        let harness = BindingHarness(authored)
        var isFocused = false
        let focus = Binding<Bool>(get: { isFocused }, set: { isFocused = $0 })

        let rendered = TextField(text: harness.binding, focus: focus).render()

        #expect(rendered == "A����Z")
        #expect(harness.value == authored)
    }

    @Test("Text field placeholders are literal-safe")
    func textFieldPlaceholder() {
        let harness = BindingHarness("")
        var isFocused = false
        let focus = Binding<Bool>(get: { isFocused }, set: { isFocused = $0 })

        let rendered = TextField("\u{001B}]0;placeholder\u{0007}", text: harness.binding, focus: focus)
            .render()

        #expect(rendered == "�]0;placeholder�")
        #expect(harness.value.isEmpty)
    }

    @Test("Text field cursor positions map across rejected scalars")
    func textFieldCursorMapping() {
        let authored = "A\u{001B}B"
        let harness = BindingHarness(authored)
        var cursor = 1
        let cursorPosition = Binding<Int>(get: { cursor }, set: { cursor = $0 })
        let field = TextField(text: harness.binding, cursorPosition: cursorPosition)

        let onControl = field.render()
        #expect(onControl.strippingANSI() == "A�B")
        #expect(onControl.contains("\u{001B}]") == false)

        cursor = 2
        let afterControl = field.render()
        #expect(afterControl.strippingANSI() == "A�B")
        #expect(cursor == 2)
        #expect(harness.value == authored)
    }

    @Test("Cursor mapping accounts for scalar expansion inside one grapheme")
    func cursorScalarExpansion() {
        let authored = "A\r\nB"
        #expect(authored.count == 3)
        #expect(
            TerminalText.literalCursorOffset(
                in: authored,
                characterOffset: 1,
                preservingLineFeeds: true
            ) == 1
        )
        #expect(
            TerminalText.literalCursorOffset(
                in: authored,
                characterOffset: 2,
                preservingLineFeeds: true
            ) == 3
        )
    }

    @Test("Text editors preserve line feeds, reject NUL, and preserve their binding")
    func textEditorBindingAndNUL() {
        let authored = "A\u{0000}B\nC\u{009B}D"
        let harness = BindingHarness(authored)
        var isFocused = false
        let focus = Binding<Bool>(get: { isFocused }, set: { isFocused = $0 })

        let rendered = TextEditor(text: harness.binding, focus: focus, width: 20).render()
            .strippingANSI()

        #expect(rendered.contains("A�B"))
        #expect(rendered.contains("C�D"))
        #expect(rendered.contains("\n"))
        #expect(rendered.contains("\u{0000}") == false)
        #expect(harness.value == authored)
    }

    @Test("Authored NUL cannot collide with the focused editor cursor marker")
    func focusedTextEditorNUL() {
        let authored = "A\u{0000}B"
        let harness = BindingHarness(authored)
        var cursor = 1
        let cursorPosition = Binding<Int>(get: { cursor }, set: { cursor = $0 })

        let rendered = TextEditor(
            text: harness.binding,
            width: 10,
            cursorPosition: cursorPosition
        ).render()

        #expect(rendered.strippingANSI().hasPrefix("A�B"))
        #expect(rendered.contains("\u{0000}") == false)
        #expect(cursor == 1)
        #expect(harness.value == authored)
    }

    @Test("Text editor placeholders are literal-safe")
    func textEditorPlaceholder() {
        let harness = BindingHarness("")
        var isFocused = false
        let focus = Binding<Bool>(get: { isFocused }, set: { isFocused = $0 })

        let rendered = TextEditor(
            "\u{001B}]0;placeholder\u{0007}",
            text: harness.binding,
            focus: focus,
            width: 30
        ).render()

        #expect(rendered.hasPrefix("�]0;placeholder�"))
        #expect(rendered.contains("\u{001B}]") == false)
    }

    private static let controlScalarValues: [UInt32] =
        Array(0x00...0x1F).map(UInt32.init)
        + Array(0x7F...0x9F).map(UInt32.init)

    private static func scalarString(_ values: [UInt32]) -> String {
        var result = ""
        for value in values {
            result.unicodeScalars.append(Unicode.Scalar(value)!)
        }
        return result
    }

    private static func expectedLiteralControls(preservingLineFeeds: Bool) -> String {
        controlScalarValues.map { value in
            value == 0x0A && preservingLineFeeds ? "\n" : "�"
        }.joined()
    }
}

private final class BindingHarness {
    @State var value: String

    init(_ value: String) {
        _value = State(wrappedValue: value)
    }

    var binding: Binding<String> { $value }
}

extension String {
    fileprivate func strippingANSI() -> String {
        var result = ""
        var inEscape = false

        for character in self {
            if inEscape {
                if character.isANSISequenceTerminator { inEscape = false }
            } else if character == "\u{001B}" {
                inEscape = true
            } else {
                result.append(character)
            }
        }

        return result
    }
}
