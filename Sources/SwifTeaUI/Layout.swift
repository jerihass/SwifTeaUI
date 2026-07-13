import Foundation

public struct Spacer: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Spacer has no body")
    }

    public init() {}
    public func render() -> String { " " }
}

public enum FrameWidth: Equatable, Sendable {
    case fixed(Int)
    case flexible(minimum: Int = 0, ideal: Int? = nil, maximum: Int? = nil, priority: Int = 0)
}

protocol WidthFrameProviding {
    var widthRule: FrameWidth { get }
    func render(allocatedWidth: Int, context: RenderContext) -> RenderedView
}

public struct WidthFrame<Content: TUIView>: TUIView, WidthFrameProviding {
    public typealias Body = Never

    public let widthRule: FrameWidth
    private let content: Content

    public init(width: FrameWidth, content: Content) {
        self.widthRule = width
        self.content = content
    }

    public var body: Never {
        fatalError("WidthFrame has no body")
    }

    public func render() -> String {
        render(in: RenderEnvironment.current)
    }

    public func render(in context: RenderContext) -> String {
        let target: Int?
        switch widthRule {
        case .fixed(let width):
            target = max(0, width)
        case .flexible(let minimum, _, let maximum, _):
            target = context.proposedSize.width.map {
                min(max(max(0, minimum), $0), maximum.map { max(max(0, minimum), $0) } ?? Int.max)
            }
        }

        guard let target else { return content.render(in: context) }
        return render(allocatedWidth: target, context: context).joined()
    }

    func render(allocatedWidth: Int, context: RenderContext) -> RenderedView {
        let target = max(0, allocatedWidth)
        let proposal = ProposedViewSize(width: target, height: context.proposedSize.height)
        let rendered = resolveRenderedView(
            for: content,
            in: RenderContext(proposedSize: proposal, fillsProposedWidth: true)
        )
        let lines = rendered.lines.isEmpty ? [""] : rendered.lines
        return RenderedView(lines: lines.map { TerminalText.fittedLine($0, to: target) })
    }
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
        render(in: RenderEnvironment.current)
    }

    public func render(in context: RenderContext) -> String {
        let childContext = RenderContext(
            proposedSize: context.proposedSize.inset(
                horizontal: inset * 2,
                vertical: inset * 2
            ),
            fillsProposedWidth: context.fillsProposedWidth
        )
        guard inset > 0 else { return content.render(in: childContext) }

        let lines = content.render(in: childContext).splitLinesPreservingEmpty()
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

extension TUIView {
    public func padding(_ inset: Int = 1) -> some TUIView {
        Padding(inset, self)
    }

    public func frame(width: FrameWidth) -> some TUIView {
        WidthFrame(width: width, content: self)
    }
}

public struct AnyTUIView: TUIView {
    public typealias Body = Never

    private let renderer: (RenderContext) -> String

    public init<V: TUIView>(_ view: V) {
        renderer = view.render(in:)
    }

    public var body: Never {
        fatalError("AnyTUIView has no body")
    }

    public func render() -> String {
        renderer(RenderEnvironment.current)
    }

    public func render(in context: RenderContext) -> String {
        renderer(context)
    }
}

// TODO: padding, borders, centers, width/height constraints, etc.
// For now left minimal to keep the example lean.
