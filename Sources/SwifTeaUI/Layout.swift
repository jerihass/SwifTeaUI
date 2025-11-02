import Foundation
import SwifTeaCore

public struct Spacer: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Spacer has no body")
    }

    public init() {}
    public func render() -> String { " " }
}

public struct Padding<Content: TUIView>: TUIView {
    public typealias Body = Never

    private let inset: Int
    private let content: Content

    public init(_ inset: Int = 1, _ content: Content) {
        self.inset = max(0, inset)
        self.content = content
    }

    public var body: Never {
        fatalError("Padding has no body")
    }

    public func render() -> String {
        guard inset > 0 else { return content.render() }

        let lines = content.render().splitLinesPreservingEmpty()
        let width = lines.map { HStack.visibleWidth(of: $0) }.max() ?? 0
        let horizontalInset = String(repeating: " ", count: inset)

        let paddedLines = lines.map { line -> String in
            let visible = HStack.visibleWidth(of: line)
            let trailing = width - visible
            return horizontalInset + line + String(repeating: " ", count: trailing) + horizontalInset
        }

        let emptyLine = String(repeating: " ", count: width + inset * 2)
        let verticalPadding = Array(repeating: emptyLine, count: inset)
        let result = verticalPadding + paddedLines + verticalPadding
        return result.joined(separator: "\n")
    }
}

public extension TUIView {
    func padding(_ inset: Int = 1) -> some TUIView {
        Padding(inset, self)
    }
}

public struct AnyTUIView: TUIView {
    public typealias Body = Never

    private let renderer: () -> String

    public init<V: TUIView>(_ view: V) {
        renderer = view.render
    }

    public var body: Never {
        fatalError("AnyTUIView has no body")
    }

    public func render() -> String {
        renderer()
    }
}

// TODO: padding, borders, centers, width/height constraints, etc.
// For now left minimal to keep the example lean.
