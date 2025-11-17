import Testing
@testable import SwifTeaUI
@testable import SwifTeaUI

@Suite(.serialized)
struct MinimumSizeTests {

    @Test("MinimumTerminalSize renders content when requirements met")
    func testContentRenderedWhenSufficient() {
        let view = MinimumTerminalSize(
            columns: 80,
            rows: 20,
            content: { Text("OK") },
            fallback: { _ in Text("Fallback") }
        )

        let rendered = TerminalDimensions.withTemporarySize(
            TerminalSize(columns: 100, rows: 30)
        ) {
            view.render()
        }

        #expect(rendered == "OK")
    }

    @Test("MinimumTerminalSize renders fallback when terminal too small")
    func testFallbackRenderedWhenInsufficient() {
        let view = MinimumTerminalSize(
            columns: 120,
            rows: 40,
            content: { Text("OK") },
            fallback: { size in Text("Fallback \(size.columns)×\(size.rows)") }
        )

        let rendered = TerminalDimensions.withTemporarySize(
            TerminalSize(columns: 80, rows: 20)
        ) {
            view.render()
        }

        #expect(rendered == "Fallback 80×20")
    }

    @Test("MinimumTerminalSize reports zero dimensions when terminal collapses")
    func testFallbackRenderedForZeroSize() {
        let view = MinimumTerminalSize(
            columns: 60,
            rows: 18,
            content: { Text("Visible") },
            fallback: { size in Text("Fallback \(size.columns)×\(size.rows)") }
        )

        let rendered = TerminalDimensions.withTemporarySize(.zero) {
            view.render()
        }

        #expect(rendered == "Fallback 0×0")
    }
}
