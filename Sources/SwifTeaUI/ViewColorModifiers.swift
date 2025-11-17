
public struct ForegroundColored<Content: TUIView>: TUIView {
    public typealias Body = Never

    private let content: Content
    private let color: ANSIColor

    public init(content: Content, color: ANSIColor) {
        self.content = content
        self.color = color
    }

    public var body: Never {
        fatalError("ForegroundColored has no body")
    }

    public func render() -> String {
        wrap(content.render(), with: color.rawValue)
    }
}

public struct BackgroundColored<Content: TUIView>: TUIView {
    public typealias Body = Never

    private let content: Content
    private let color: ANSIColor

    public init(content: Content, color: ANSIColor) {
        self.content = content
        self.color = color
    }

    public var body: Never {
        fatalError("BackgroundColored has no body")
    }

    public func render() -> String {
        wrap(content.render(), with: color.backgroundCode)
    }
}

public extension TUIView {
    func foregroundColor(_ color: ANSIColor) -> some TUIView {
        ForegroundColored(content: self, color: color)
    }

    func backgroundColor(_ color: ANSIColor) -> some TUIView {
        BackgroundColored(content: self, color: color)
    }
}

private func wrap(_ rendered: String, with prefix: String) -> String {
    guard !rendered.isEmpty else { return "" }
    guard !prefix.isEmpty else { return rendered }
    if prefix == ANSIColor.reset.rawValue { return rendered }

    let reset = ANSIColor.reset.rawValue
    let reapplying = rendered.replacingOccurrences(of: reset, with: reset + prefix)
    return prefix + reapplying + reset
}
