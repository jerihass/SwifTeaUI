import Foundation
import SwifTeaCore

public struct Text: TUIView {
    let content: String
    var color: ANSIColor? = nil
    var bold: Bool = false

    public init(_ content: String) { self.content = content }

    public func foreground(_ color: ANSIColor) -> Text {
        var copy = self; copy.color = color; return copy
    }

    public func bolded() -> Text {
        var copy = self; copy.bold = true; return copy
    }

    public func render() -> String {
        var s = content
        if bold { s = "\u{001B}[1m" + s + ANSIColor.reset.rawValue }
        if let c = color { s = c.rawValue + s + ANSIColor.reset.rawValue }
        return s
    }
}

public struct VStack: TUIView {
    let children: [TUIView]

    public init(@TUIBuilder _ content: () -> [TUIView]) {
        self.children = content()
    }

    public func render() -> String {
        children.map { $0.render() }.joined(separator: "\n")
    }
}

public struct HStack: TUIView {
    public enum Alignment {
        case leading
        case center
        case trailing
    }

    let children: [TUIView]
    let spacing: Int
    let alignment: Alignment

    public init(
        spacing: Int = 3,
        alignment: Alignment = .leading,
        @TUIBuilder _ content: () -> [TUIView]
    ) {
        self.children = content()
        self.spacing = max(0, spacing)
        self.alignment = alignment
    }

    public func render() -> String {
        guard !children.isEmpty else { return "" }

        let renderedColumns = children.map { $0.render().splitLinesPreservingEmpty() }
        let columnWidths = renderedColumns.map { $0.map(Self.visibleWidth(of:)).max() ?? 0 }
        let maxRows = renderedColumns.map(\.count).max() ?? 0
        let spacingString = String(repeating: " ", count: spacing)

        var rows: [String] = []
        rows.reserveCapacity(maxRows)

        for row in 0..<maxRows {
            var pieces: [String] = []
            pieces.reserveCapacity(children.count)

            for (index, lines) in renderedColumns.enumerated() {
                let line = row < lines.count ? lines[row] : ""
                let padded = Self.pad(
                    line,
                    toVisibleWidth: columnWidths[index],
                    alignment: alignment
                )
                pieces.append(padded)
            }

            rows.append(pieces.joined(separator: spacingString))
        }

        return rows.joined(separator: "\n")
    }

    private static func visibleWidth(of string: String) -> Int {
        var width = 0
        var index = string.startIndex
        var inEscape = false

        while index < string.endIndex {
            let character = string[index]

            if inEscape {
                if character.isANSISequenceTerminator {
                    inEscape = false
                }
            } else if character == "\u{001B}" {
                inEscape = true
            } else {
                width += 1
            }

            index = string.index(after: index)
        }

        return width
    }

    private static func pad(
        _ line: String,
        toVisibleWidth width: Int,
        alignment: Alignment
    ) -> String {
        let currentWidth = visibleWidth(of: line)
        guard currentWidth < width else { return line }

        let padding = width - currentWidth
        switch alignment {
        case .leading:
            return line + String(repeating: " ", count: padding)
        case .trailing:
            return String(repeating: " ", count: padding) + line
        case .center:
            let leading = padding / 2
            let trailing = padding - leading
            return String(repeating: " ", count: leading) + line + String(repeating: " ", count: trailing)
        }
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

// SwiftUI-esque result builder
@resultBuilder
public struct TUIBuilder {
    public static func buildBlock(_ components: TUIView...) -> [TUIView] { components }
}
