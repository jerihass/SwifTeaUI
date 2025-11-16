import Testing
import SnapshotTestSupport
@testable import SwifTeaCore
@testable import SwifTeaUI

struct BorderTests {

    @Test("Border applies a default padding of one space on each side")
    func testDefaultPadding() {
        let bordered = Border(Text("Hi"))
        #expect(bordered.render() == """
┌────┐
│ Hi │
└────┘
""")
    }

    @Test("Border renders without padding when configured with zero")
    func testZeroPadding() {
        let bordered = Border(padding: 0, Text("Hi"))
        #expect(bordered.render() == """
┌──┐
│Hi│
└──┘
""")
    }

    @Test("border modifier forwards padding to the border view")
    func testBorderModifierPadding() {
        let view = Text("Hi").border(padding: 0)
        let expected = Border(padding: 0, Text("Hi")).render()
        #expect(view.render() == expected)
    }

    @Test("Focus ring styling colors only the border characters")
    func testFocusRingStyling() {
        let style = FocusStyle(indicator: "> ", color: .cyan, bold: true)
        let border = FocusRingBorder(padding: 0, isFocused: true, style: style, Text("Hi"))
        let lines = border.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let focusRing = FocusRingSnapshotAsserter(style: style)
        let wrappedTop = focusRing.wrapped("┌──┐")
        let wrappedSide = focusRing.wrapped("│")
        let wrappedBottom = focusRing.wrapped("└──┘")

        #expect(lines.count == 3)
        #expect(lines[0] == wrappedTop)
        #expect(lines[1] == wrappedSide + "Hi" + wrappedSide)
        #expect(lines[2] == wrappedBottom)
        #expect(!lines.joined(separator: "\n").contains("> "))
    }

    @Test("Focus ring skips styling when view is not focused")
    func testFocusRingUnfocused() {
        let style = FocusStyle(indicator: "", color: .cyan, bold: true)
        let border = FocusRingBorder(padding: 0, isFocused: false, style: style, Text("Hi"))
        let expected = """
┌──┐
│Hi│
└──┘
"""
        #expect(border.render() == expected)
    }

    @Test("Border background color fills interior without overriding content backgrounds")
    func testBorderBackgroundColor() {
        let border = Border(
            padding: 0,
            background: .blue,
            Text("Hi").backgroundColor(.brightGreen)
        )
        let rendered = border.render()
        let lines = rendered.splitLinesPreservingEmpty()
        #expect(lines.count == 3)

        let prefix = ANSIColor.blue.backgroundCode
        let reset = ANSIColor.reset.rawValue

        #expect(lines[0].hasPrefix(prefix))
        #expect(lines[0].hasSuffix(reset))
        #expect(lines[2].hasPrefix(prefix))
        #expect(lines[2].hasSuffix(reset))

        let middle = lines[1]
        #expect(middle.contains(prefix + "│"))
        #expect(middle.contains("│" + reset))
        #expect(rendered.contains(ANSIColor.brightGreen.backgroundCode))

        let ascii = """
┌──┐
│Hi│
└──┘
"""
        #expect(rendered.removingANSISequences() == ascii)
    }

    @Test("Nested borders preserve interior backgrounds")
    func testNestedBorderBackgrounds() {
        let inner = Border(
            padding: 0,
            color: .brightYellow,
            background: .brightBlack,
            Text("Hi").backgroundColor(.brightGreen)
        )
        let outer = Border(
            padding: 1,
            color: .brightBlue,
            background: .blue,
            inner
        )

        let rendered = outer.render()
        #expect(rendered.contains(ANSIColor.blue.backgroundCode))
        #expect(rendered.contains(ANSIColor.brightBlack.backgroundCode))
        #expect(rendered.contains(ANSIColor.brightGreen.backgroundCode))

        let expectedASCII = """
┌────────┐
│        │
│ ┌──┐   │
│ │Hi│   │
│ └──┘   │
│        │
└────────┘
"""
        #expect(rendered.removingANSISequences() == expectedASCII)
    }
}

private extension String {
    func removingANSISequences() -> String {
        var result = ""
        var inEscape = false
        for character in self {
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
