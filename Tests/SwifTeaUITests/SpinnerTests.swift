import Foundation
import Testing
@testable import SwifTeaCore
@testable import SwifTeaUI

struct SpinnerTests {

    @Test("Spinner cycles frames using shared timeline")
    func testSpinnerAdvancesWithTime() {
        let previousTimeline = SpinnerTimeline.shared
        defer { SpinnerTimeline.shared = previousTimeline }

        var timeline = SpinnerTimeline.shared
        timeline.timeProvider = { 0 }
        SpinnerTimeline.shared = timeline

        let spinner = Spinner(style: .ascii)
        #expect(spinner.render() == "-")

        timeline = SpinnerTimeline.shared
        timeline.timeProvider = { Spinner.Style.ascii.interval }
        SpinnerTimeline.shared = timeline

        #expect(spinner.render() == "\\")
    }

    @Test("Spinner applies color and label when provided")
    func testSpinnerFormatting() {
        let previousTimeline = SpinnerTimeline.shared
        defer { SpinnerTimeline.shared = previousTimeline }

        var timeline = SpinnerTimeline.shared
        timeline.timeProvider = { 0 }
        SpinnerTimeline.shared = timeline

        let spinner = Spinner(
            label: "Loading",
            style: .ascii,
            color: .cyan,
            isBold: true
        )

        #expect(
            spinner.render()
            == "\(ANSIColor.cyan.rawValue)\u{001B}[1m-\(ANSIColor.reset.rawValue) \(ANSIColor.cyan.rawValue)Loading\(ANSIColor.reset.rawValue)"
        )
    }

    @Test("Spinner can be paused")
    func testSpinnerPaused() {
        let previousTimeline = SpinnerTimeline.shared
        defer { SpinnerTimeline.shared = previousTimeline }

        var timeline = SpinnerTimeline.shared
        timeline.timeProvider = { 0 }
        SpinnerTimeline.shared = timeline

        let spinner = Spinner(style: .ascii, isSpinning: false)
        #expect(spinner.render() == " ")
    }

    @Test("Additional spinner styles render distinct frames")
    func testAdditionalStyles() {
        let previousTimeline = SpinnerTimeline.shared
        defer { SpinnerTimeline.shared = previousTimeline }

        var timeline = SpinnerTimeline.shared
        timeline.timeProvider = { 0 }
        SpinnerTimeline.shared = timeline

        let dots = Spinner(style: .dots)
        let line = Spinner(style: .line)

        #expect(dots.render().trimmingCharacters(in: .whitespaces) == ".")
        #expect(line.render() == "⎺")
    }
}
