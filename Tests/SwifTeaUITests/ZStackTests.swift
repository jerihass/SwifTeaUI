import Testing
@testable import SwifTeaUI

struct ZStackTests {

    @Test("Overlay draws on top of base")
    func testSimpleOverlay() {
        let stack = ZStack(alignment: .topLeading) {
            Text("Hello")
            Text("++")
        }

        let rendered = stack.render()
        #expect(rendered.hasPrefix("++llo"))
    }

    @Test("Alignment centers overlay content")
    func testCenterAlignment() {
        let stack = ZStack(alignment: .center) {
            Text("------\n------\n------")
            Text("XX\nXX")
        }

        let lines = stack.render().split(separator: "\n").map(String.init)
        #expect(lines.count == 3)
        #expect(lines[1].contains("XX"))
    }

    @Test("Overlay styles stay within coverage bounds")
    func testOverlayStyleResetWithinBounds() {
        let stack = ZStack(alignment: .topLeading) {
            Text("HelloWorld")
            Text("Hi").backgroundColor(.brightMagenta)
        }

        let rendered = stack.render()
        let resetSequence = ANSIColor.reset.rawValue
        #expect(rendered.contains(resetSequence + "lloWorld"))
    }

    @Test("Base colors resume after overlay")
    func testBaseColorRestorationAfterOverlay() {
        let stack = ZStack(alignment: .topLeading) {
            Text("Hello").backgroundColor(.brightBlue)
            Text("++")
        }

        let rendered = stack.render()
        let expected = ANSIColor.brightBlue.backgroundCode + "llo"
        #expect(rendered.contains(expected))
    }
}
