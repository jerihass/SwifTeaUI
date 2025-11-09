import Testing
@testable import SwifTeaUI

struct TextStyleTests {
    @Test("foregroundColor wraps content once")
    func testColor() {
        let rendered = Text("Hi").foregroundColor(.green).render()
        #expect(rendered == "\u{001B}[32mHi\u{001B}[0m")
    }

    @Test("bold wraps content once")
    func testBold() {
        let rendered = Text("Hi").bold().render()
        #expect(rendered == "\u{001B}[1mHi\u{001B}[0m")
    }

    @Test("color and bold combine regardless of modifier order")
    func testColorAndBold() {
        let first = Text("Hi").foregroundColor(.yellow).bold().render()
        let second = Text("Hi").bold().foregroundColor(.yellow).render()
        let expected = "\u{001B}[33m\u{001B}[1mHi\u{001B}[0m"
        #expect(first == expected)
        #expect(second == expected)
    }

    @Test("italic wraps content once")
    func testItalic() {
        let rendered = Text("Hi").italic().render()
        #expect(rendered == "\u{001B}[3mHi\u{001B}[0m")
    }

    @Test("bold color italic combine")
    func testAllStyles() {
        let rendered = Text("Hi")
            .foregroundColor(.cyan)
            .bold()
            .italic()
            .render()
        #expect(rendered == "\u{001B}[36m\u{001B}[1m\u{001B}[3mHi\u{001B}[0m")
    }
}
