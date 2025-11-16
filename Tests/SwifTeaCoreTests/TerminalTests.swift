import Foundation
import Testing
@testable import SwifTeaCore

#if os(Linux)
import Glibc
#else
import Darwin
#endif

@Suite(.serialized)
struct TerminalTests {

    @Test("Cursor helpers emit ANSI visibility sequences")
    func testCursorVisibilityHelpers() {
        let pipe = Pipe()

        let original = dup(STDOUT_FILENO)
        #expect(original != -1)

        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        hideCursor()
        showCursor()

        fflush(stdout)
        pipe.fileHandleForWriting.closeFile()

        dup2(original, STDOUT_FILENO)
        close(original)

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)

        #expect(output == "\u{001B}[?25l\u{001B}[?25h")
    }

    @Test("TerminalDimensions override temporary size within closure")
    func testTerminalSizeOverride() {
        let baseline = TerminalDimensions.current
        let custom = TerminalSize(columns: baseline.columns + 7, rows: baseline.rows + 3)

        TerminalDimensions.withTemporarySize(custom) {
            #expect(TerminalDimensions.current == custom)
            #expect(TerminalDimensions.refresh() == custom)
        }

        #expect(TerminalDimensions.current != TerminalSize.zero)
        #expect(TerminalDimensions.current != custom)
    }

    @Test("Terminal metrics classify width and height size classes")
    func testTerminalMetricsSizeClasses() {
        let compact = TerminalMetrics(
            size: TerminalSize(columns: 80, rows: 20),
            compactWidthThreshold: 90,
            compactHeightThreshold: 25
        )
        #expect(compact.horizontalSizeClass == .compact)
        #expect(compact.verticalSizeClass == .compact)
        #expect(compact.isCompact)

        let regular = TerminalMetrics(
            size: TerminalSize(columns: 140, rows: 50),
            compactWidthThreshold: 90,
            compactHeightThreshold: 25
        )
        #expect(regular.horizontalSizeClass == .regular)
        #expect(regular.verticalSizeClass == .regular)
        #expect(!regular.isCompact)
    }

    @Test("Frame padding resets colors before trailing spaces")
    func testFramePaddingResetsColor() {
        let red = "\u{001B}[31m"
        let reset = ANSIColor.reset.rawValue
        let input = "\(red)brew\(reset)"

        let padded = input.padded(toVisibleWidth: 10)
        #expect(padded.hasSuffix(reset + String(repeating: " ", count: 6)))

        let multiline = "\(input)\n\(input)"
        let processed = multiline.padded(toVisibleWidth: 10)
        let expectedPadding = reset + String(repeating: " ", count: 6)
        #expect(processed.contains(expectedPadding + "\n"))
        #expect(processed.hasSuffix(expectedPadding))
    }
}
