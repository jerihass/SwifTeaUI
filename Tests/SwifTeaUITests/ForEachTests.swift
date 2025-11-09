import Testing
@testable import SwifTeaUI

struct ForEachTests {
    @Test("ForEach renders each element vertically")
    func testRendersSequence() {
        let view = ForEach(["One", "Two", "Three"], id: \.self) { value in
            Text(value)
        }

        let output = view.render().split(separator: "\n").map(String.init)
        #expect(output == ["One", "Two", "Three"])
    }

    @Test("ForEach handles enumerated data with tuple elements")
    func testEnumeratedSequence() {
        let data = Array(["A", "B", "C"].enumerated())
        let view = ForEach(data, id: \.offset) { entry in
            let (index, value) = entry
            return Text("\(index):\(value)")
        }

        let output = view.render().split(separator: "\n").map(String.init)
        #expect(output == ["0:A", "1:B", "2:C"])
    }

    @Test("ForEach infers IDs from Identifiable data without explicit id key path")
    func testIdentifiableData() {
        struct Item: Identifiable {
            let id: Int
            let name: String
        }
        let items = [
            Item(id: 1, name: "Alpha"),
            Item(id: 2, name: "Beta")
        ]

        let view = ForEach(items) { item in
            Text(item.name)
        }

        let output = view.render().split(separator: "\n").map(String.init)
        #expect(output == ["Alpha", "Beta"])
    }
}
