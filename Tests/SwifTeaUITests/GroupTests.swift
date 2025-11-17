import Testing
import SwifTeaUI
@testable import SwifTeaUI

struct GroupTests {
    @Test("Group concatenates conditional children without extra layout")
    func testConditionalContent() {
        let includeDetails = true

        let view = Group {
            Text("Header")
            if includeDetails {
                Text("Details")
            } else {
                Text("Fallback")
            }
            Text("Footer")
        }

        let lines = view.render().split(separator: "\n").map(String.init)
        #expect(lines == ["Header", "Details", "Footer"])
    }

    @Test("Group flattens inside parent stacks without extra layout")
    func testFlattenedInHStack() {
        let view = HStack(spacing: 0) {
            Group {
                Text("A")
                Text("B")
            }
            Text("C")
        }

        #expect(view.render() == "ABC")
    }
}
