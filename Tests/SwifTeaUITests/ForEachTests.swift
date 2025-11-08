import Testing
@testable import SwifTeaUI

struct ForEachTests {
    @Test("ForEach renders each element vertically")
    func testRendersSequence() {
        let view = ForEach(["One", "Two", "Three"]) { value in
            Text(value)
        }

        let output = view.render().split(separator: "\n").map(String.init)
        #expect(output == ["One", "Two", "Three"])
    }

    @Test("ForEach handles enumerated data with tuple elements")
    func testEnumeratedSequence() {
        let data = Array(["A", "B", "C"].enumerated())
        let view = ForEach(data) { entry in
            let (index, value) = entry
            return Text("\(index):\(value)")
        }

        let output = view.render().split(separator: "\n").map(String.init)
        #expect(output == ["0:A", "1:B", "2:C"])
    }
}
