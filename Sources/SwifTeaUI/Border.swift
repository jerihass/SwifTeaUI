import SwifTeaCore

public struct Border<Content: TUIView>: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Border has no body")
    }

    private let content: Content
    private let padding: Int

    public init(_ content: Content) {
        self.init(padding: 1, content)
    }

    public init(padding: Int, _ content: Content) {
        precondition(padding >= 0, "Border padding must be non-negative.")
        self.content = content
        self.padding = padding
    }

    public func render() -> String {
        let inner = content.render()
        let lines = inner.splitLinesPreservingEmpty()
        let width = lines.map { Self.visibleWidth(of: $0) }.max() ?? 0
        let paddingString = String(repeating: " ", count: padding)
        let horizontal = String(repeating: "─", count: width + padding * 2)
        let top = "┌" + horizontal + "┐"
        let bottom = "└" + horizontal + "┘"

        let body = lines.map { line -> String in
            let padded = Self.pad(line, toVisibleWidth: width)
            return "│" + paddingString + padded + paddingString + "│"
        }

        return ([top] + body + [bottom]).joined(separator: "\n")
    }

    private static func visibleWidth(of string: String) -> Int {
        var width = 0
        var iterator = string.makeIterator()
        var inEscape = false

        while let character = iterator.next() {
            if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
            } else if character == "\u{001B}" {
                inEscape = true
            } else {
                width += 1
            }
        }

        return width
    }

    private static func pad(_ line: String, toVisibleWidth width: Int) -> String {
        let current = visibleWidth(of: line)
        guard current < width else { return line }
        let padding = width - current
        return line + String(repeating: " ", count: padding)
    }
}

public extension TUIView {
    func border(padding: Int = 1) -> some TUIView {
        Border(padding: padding, self)
    }
}

private extension String {
    func splitLinesPreservingEmpty() -> [String] {
        if isEmpty { return [""] }
        var lines: [String] = []
        lines.reserveCapacity(count / 8)

        var current = ""
        for character in self {
            if character == "\n" {
                lines.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        lines.append(current)
        return lines
    }
}

private extension Character {
    var isANSISequenceTerminator: Bool {
        switch self {
        case "a"..."z", "A"..."Z":
            return true
        default:
            return false
        }
    }
}
