import Testing
@testable import SwifTeaUI
@testable import SwifTeaUI

struct ViewColorModifierTests {
    @Test("Foreground modifier wraps composite view output")
    func testForegroundWrapper() {
        let view = VStack(spacing: 1) {
            Text("Hello")
            Text("World")
        }.foregroundColor(.cyan)

        let output = view.render()
        #expect(output.hasPrefix(ANSIColor.cyan.rawValue))
        #expect(output.hasSuffix(ANSIColor.reset.rawValue))
    }

    @Test("Background modifier applies ANSI background escape")
    func testBackgroundWrapper() {
        let view = HStack {
            Text("One")
            Text("Two")
        }.backgroundColor(.yellow)

        let output = view.render()
        #expect(output.hasPrefix(ANSIColor.yellow.backgroundCode))
        #expect(output.hasSuffix(ANSIColor.reset.rawValue))
    }

    @Test("Stack modifiers compose when nesting foreground and background")
    func testNestedColorModifiers() {
        let view = VStack {
            Text("Item")
        }
        .foregroundColor(.green)
        .backgroundColor(.cyan)

        let output = view.render()
        #expect(output.hasPrefix(ANSIColor.cyan.backgroundCode + ANSIColor.green.rawValue))
        #expect(output.hasSuffix(ANSIColor.reset.rawValue))
    }
}
