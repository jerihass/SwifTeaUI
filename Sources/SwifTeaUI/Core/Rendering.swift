import Foundation

private final class DiffFrameRenderer: @unchecked Sendable {
    private let lock = NSLock()
    private var lastLines: [String] = []
    private var needsFullRedraw = true

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        lastLines = []
        needsFullRedraw = true
    }

    func render(frame: String, columns: Int) {
        lock.lock()
        defer { lock.unlock() }

        let prepared: String
        if columns > 0 {
            prepared = frame.padded(toVisibleWidth: columns)
        } else {
            prepared = frame
        }

        let lines = prepared.splitLinesPreservingEmpty()
        // First paint or forced reset: full redraw.
        if needsFullRedraw || lastLines.isEmpty {
            moveCursorHome()
            writeToStdout(prepared)
            clearBelowCursor()
            lastLines = lines
            needsFullRedraw = false
            return
        }

        var buffer = String()

        let lineCount = max(lines.count, lastLines.count)
        for index in 0..<lineCount {
            let newLine = index < lines.count ? lines[index] : ""
            let oldLine = index < lastLines.count ? lastLines[index] : nil
            if let oldLine, newLine == oldLine {
                continue
            }
            buffer.append(cursorMove(row: index + 1, column: 1))
            buffer.append(clearLine())
            buffer.append(newLine)
        }

        if lines.count < lastLines.count {
            buffer.append(cursorMove(row: lines.count + 1, column: 1))
            buffer.append("\u{001B}[J")  // clear below cursor
        }

        guard !buffer.isEmpty else {
            lastLines = lines
            return
        }

        writeToStdout(buffer)
        lastLines = lines
    }

    private func cursorMove(row: Int, column: Int) -> String {
        "\u{001B}[\(row);\(column)H"
    }

    private func clearLine() -> String {
        "\u{001B}[2K"
    }
}

private let frameRenderer = DiffFrameRenderer()

func resetFrameRenderer() {
    frameRenderer.reset()
}

final class FrameLogger {
    private let handle: FileHandle
    private var frameIndex: Int = 0

    private init?(path: String) {
        let manager = FileManager.default
        if manager.fileExists(atPath: path) {
            try? manager.removeItem(atPath: path)
        }

        _ = manager.createFile(atPath: path, contents: nil, attributes: nil)

        guard let handle = FileHandle(forWritingAtPath: path) else {
            return nil
        }

        self.handle = handle
    }

    deinit {
        try? handle.close()
    }

    static func make() -> FrameLogger? {
        guard let path = ProcessInfo.processInfo.environment["SWIFTEA_FRAME_LOG"],
            !path.isEmpty
        else { return nil }
        return FrameLogger(path: path)
    }

    func log(_ frame: String, changed: Bool, forced: Bool) {
        frameIndex += 1
        let header = "\n--- frame \(frameIndex) (changed: \(changed) forced: \(forced)) ---\n"
        guard let headerData = header.data(using: .utf8),
            let frameData = frame.data(using: .utf8),
            let newline = "\n".data(using: .utf8)
        else { return }

        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: headerData)
            try handle.write(contentsOf: frameData)
            try handle.write(contentsOf: newline)
        } catch {
            // Best-effort logging; ignore write failures.
        }
    }
}

@inline(__always)
func moveCursorHome() {
    writeToStdout("\u{001B}[H")
}

@inline(__always)
func clearBelowCursor() {
    writeToStdout("\u{001B}[J")
}

@inline(__always)
func renderFrame(_ frame: String) {
    frameRenderer.render(frame: frame, columns: TerminalDimensions.current.columns)
}

@inline(__always)
func writeToStdout(_ string: String) {
    guard !string.isEmpty, let data = string.data(using: .utf8) else { return }
    try? FileHandle.standardOutput.write(contentsOf: data)
}

extension String {
    func padded(toVisibleWidth width: Int) -> String {
        guard width > 0 else { return self }
        return split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).fittedLine(toVisibleWidth: width) }
            .joined(separator: "\n")
    }

    private func fittedLine(toVisibleWidth width: Int) -> String {
        TerminalText.fittedLine(self, to: width)
    }
}
