public struct OverlayHost<Content: TUIView>: TUIView {
    public typealias Body = Never

    private let presenter: OverlayPresenter
    private let content: Content

    public init(
        presenter: OverlayPresenter,
        content: Content
    ) {
        self.presenter = presenter
        self.content = content
    }

    public init(
        presenter: OverlayPresenter,
        content: () -> Content
    ) {
        self.init(presenter: presenter, content: content())
    }

    public var body: Never {
        fatalError("OverlayHost has no composed body")
    }

    public func render() -> String {
        if let modal = presenter.activeModal {
            return ModalOverlay(base: content, modal: modal).render()
        }

        var baseLines = content.render().splitLinesPreservingEmpty()
        if baseLines.isEmpty {
            baseLines = [""]
        }

        overlay(toasts: presenter.topToasts, onto: &baseLines, fromTop: true)
        overlay(toasts: presenter.bottomToasts, onto: &baseLines, fromTop: false)

        return baseLines.joined(separator: "\n")
    }

    private func overlay(
        toasts: [OverlayPresenter.ToastSnapshot],
        onto lines: inout [String],
        fromTop: Bool
    ) {
        guard !toasts.isEmpty else { return }

        var offset = 0
        for toast in fromTop ? toasts : toasts.reversed() {
            let rendered = toast.view.render().splitLinesPreservingEmpty()
            guard !rendered.isEmpty else { continue }

            for (index, toastLine) in rendered.enumerated() {
                let targetIndex: Int
                if fromTop {
                    targetIndex = offset + index
                } else {
                    targetIndex = lines.count - 1 - offset - (rendered.count - 1 - index)
                }

                guard lines.indices.contains(targetIndex) else { continue }
                let baseWidth = HStack.visibleWidth(of: lines[targetIndex])
                lines[targetIndex] = toastLine.padded(toVisibleWidth: max(baseWidth, HStack.visibleWidth(of: toastLine)))
            }

            offset += rendered.count + 1
            if offset >= lines.count {
                break
            }
        }
    }
}

private struct ModalOverlay<Base: TUIView>: TUIView {
    let base: Base
    let modal: OverlayPresenter.ModalSnapshot

    var body: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            base.foregroundColor(.brightBlack)
            Text("")
            Border(
                padding: 2,
                color: modal.style.borderColor,
                background: .black,
                VStack(spacing: 1, alignment: .leading) {
                    if let title = modal.title {
                        Text(title)
                            .foregroundColor(modal.style.titleColor)
                            .bold()
                    }
                    modal.view
                }
            )
        }
    }
}
