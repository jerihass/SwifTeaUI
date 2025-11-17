import Testing
import SwifTeaUI
@testable import SwifTeaUI

struct ScrollViewTests {
    @Test("Vertical ScrollView clamps offset and renders visible window")
    func testVerticalScrolling() {
        let content = (1...6).map { "Line \($0)" }.joined(separator: "\n")
        var offset = 4
        let binding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )

        let view = ScrollView(viewport: 3, offset: binding) {
            Text(content)
        }

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["Line 4", "Line 5", "Line 6"])
        #expect(offset == 3)
    }

    @Test("ScrollView pads when content shorter than viewport")
    func testViewportPadding() {
        var offset = 0
        let binding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )
        let view = ScrollView(viewport: 4, offset: binding) {
            Text("Only one line")
        }

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["Only one line", "", "", ""])
    }

    @Test("Pinned ScrollView stays at bottom when content grows")
    func testPinnedFollowsBottom() {
        var offset = 0
        var pinned = true
        var length = 0

        let offsetBinding = Binding(
            get: { offset },
            set: { offset = $0 }
        )
        let pinnedBinding = Binding(
            get: { pinned },
            set: { pinned = $0 }
        )
        let lengthBinding = Binding(
            get: { length },
            set: { length = $0 }
        )

        let view = ScrollView(
            viewport: 2,
            offset: offsetBinding,
            pinnedToBottom: pinnedBinding,
            contentLength: lengthBinding
        ) {
            Text("1\n2\n3\n4")
        }

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["3", "4"])
        #expect(offset == 2)
        #expect(length == 4)
    }

    @Test("Horizontal ScrollView clamps offset and slices width")
    func testHorizontalScrolling() {
        var offset = 10
        let binding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )

        let view = ScrollView(.horizontal, viewport: 4, offset: binding) {
            Text("abcdef\n123456")
        }

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["cdef", "3456"])
        #expect(offset == 2)
    }

    @Test("Scroll indicators decorate visible window when enabled")
    func testVerticalIndicators() {
        var offset = 1
        let binding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )

        let view = ScrollView(viewport: 2, offset: binding) {
            Text("A\nB\nC\nD")
        }
        .scrollIndicators(.automatic)

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["↑B", "↓C"])
    }

    @Test("Horizontal indicators add leading and trailing glyphs")
    func testHorizontalIndicators() {
        var offset = 1
        let binding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )

        let view = ScrollView(.horizontal, viewport: 3, offset: binding) {
            Text("abcdef")
        }
        .scrollIndicators(.automatic)

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["←bcd→"])
    }

    @Test("scrollDisabled prevents automatic offset changes")
    func testScrollDisabledPreventsAutoFollow() {
        var offset = 0
        var pinned = true

        let offsetBinding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )
        let pinnedBinding = Binding<Bool>(
            get: { pinned },
            set: { pinned = $0 }
        )

        let view = ScrollView(
            viewport: 2,
            offset: offsetBinding,
            pinnedToBottom: pinnedBinding
        ) {
            Text("1\n2\n3\n4")
        }
        .scrollDisabled()

        let lines = view.render().split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines == ["1", "2"])
        #expect(offset == 0)
    }

    @Test("followingActiveLine helper keeps caret visible")
    func testFollowingActiveLineHelper() {
        var offset = 0
        var line = 4
        var follow = true

        let offsetBinding = Binding<Int>(
            get: { offset },
            set: { offset = $0 }
        )
        let lineBinding = Binding<Int>(
            get: { line },
            set: { line = $0 }
        )
        let followBinding = Binding<Bool>(
            get: { follow },
            set: { follow = $0 }
        )

        let view = ScrollView(viewport: 2, offset: offsetBinding) {
            Text((1...5).map(String.init).joined(separator: "\n"))
        }
        .followingActiveLine(lineBinding, enabled: followBinding)

        _ = view.render()
        #expect(offset == 3)
    }
}
