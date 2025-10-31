import Foundation
import Testing
@testable import SwifTeaCore

#if os(Linux)
import Glibc
#else
import Darwin
#endif

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
}
