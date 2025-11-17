import Testing
@testable import SwifTeaUI
@testable import SwifTeaUI

struct StatusBarTests {

    @Test("Status bar renders colored leading and trailing segments")
    func testSegmentRendering() {
        let status = StatusBar(
            leading: [
                .init("Mode: View", color: .yellow)
            ],
            trailing: [
                .init("q Quit", color: .cyan)
            ]
        )

        #expect(status.render() == """
\(ANSIColor.yellow.rawValue)Mode: View\(ANSIColor.reset.rawValue)  \(ANSIColor.cyan.rawValue)q Quit\(ANSIColor.reset.rawValue)
""")
    }

    @Test("Status bar pads trailing segments to match requested width")
    func testWidthPadding() {
        let status = StatusBar(
            width: 12,
            leading: [.init("A")],
            trailing: [.init("B")]
        )

        #expect(status.render() == "A" + String(repeating: " ", count: 10) + "B")
    }
}
