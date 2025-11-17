import Foundation
import Testing
@testable import SwifTeaUI
@testable import SwifTeaUI

struct ProgressMeterTests {

    @Test("Progress meter shows zero percent with empty bar")
    func testZeroProgress() {
        let style = ProgressMeter.Style(fill: "#", empty: ".")
        let meter = ProgressMeter(value: 0, width: 10, style: style)
        #expect(meter.render() == "[..........]   0%")
    }

    @Test("Progress meter clamps value into range")
    func testClampedProgress() {
        let style = ProgressMeter.Style(fill: "*", empty: "-")
        let meter = ProgressMeter(value: 1.5, width: 5, style: style)
        #expect(meter.render() == "[*****] 100%")
    }

    @Test("Progress meter renders intermediate percentage")
    func testIntermediateProgress() {
        let meter = ProgressMeter(value: 0.42, width: 10, style: .ascii)
        #expect(meter.render() == "[====      ]  42%")
    }

    @Test("Progress meter applies color tint when style specifies color")
    func testTintedProgressMeter() {
        let meter = ProgressMeter(value: 0.5, width: 4, style: .tinted(.cyan))
        let rendered = meter.render()
        #expect(rendered.contains(ANSIColor.cyan.rawValue))
        #expect(rendered.strippingANSI() == "[##  ]  50%")
    }
}

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
