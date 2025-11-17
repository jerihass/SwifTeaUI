import Testing
import SnapshotTestSupport
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
}

struct SidebarTests {

    @Test("Sidebar renders default indicators and colors")
    func testSidebarRendering() {
        let sidebar = Sidebar(
            title: "Notes",
            items: ["One", "Two"],
            selection: 0,
            isFocused: false
        ) { $0 }

        let rendered = sidebar.render()
        let expected = """
┌────────┐
│ Notes  │
│ >  One │
│    Two │
└────────┘
"""
        #expect(rendered.strippingANSI() == expected)
        let focusRing = FocusRingSnapshotAsserter()
        focusRing.expect(in: rendered, excludes: ["┌────────┐", "│"])
    }

    @Test("Sidebar highlights selection when focused")
    func testFocusedSelection() {
        let sidebar = Sidebar(
            title: "Notes",
            items: ["One", "Two"],
            selection: 1,
            isFocused: true
        ) { $0 }

        let rendered = sidebar.render()
        let expected = """
┌────────┐
│ Notes  │
│    One │
│ >▌ Two │
└────────┘
"""
        let stripped = rendered.strippingANSI()
        #expect(stripped == expected)
        let focusRing = FocusRingSnapshotAsserter()
        focusRing.expect(in: rendered, contains: ["┌────────┐", "│"])
    }
}
