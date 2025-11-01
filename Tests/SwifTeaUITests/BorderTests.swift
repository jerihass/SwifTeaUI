import Testing
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
}
