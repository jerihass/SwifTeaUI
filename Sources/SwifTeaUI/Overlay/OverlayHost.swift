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
                lines[targetIndex] = overlayLine(
                    toastLine,
                    onto: lines[targetIndex]
                )
            }

            offset += rendered.count + 1
            if offset >= lines.count {
                break
            }
        }
    }

    private func overlayLine(_ toastLine: String, onto baseLine: String) -> String {
        let toastWidth = HStack.visibleWidth(of: toastLine)
        guard toastWidth > 0 else { return baseLine }
        let baseRemainder = dropLeadingVisibleColumns(from: baseLine, count: toastWidth)
        return toastLine + baseRemainder
    }

    private func dropLeadingVisibleColumns(from line: String, count: Int) -> String {
        guard count > 0 else { return line }

        var visibleIndex = 0
        var capturing = false
        var result = ""
        var pendingSequences = ""
        var index = line.startIndex
        var inEscape = false
        var currentSequence = ""

        while index < line.endIndex {
            let character = line[index]
            if inEscape {
                currentSequence.append(character)
                if character.isANSISequenceTerminator {
                    inEscape = false
                    if capturing {
                        result.append(currentSequence)
                    } else {
                        pendingSequences.append(currentSequence)
                    }
                    currentSequence.removeAll(keepingCapacity: true)
                }
            } else if character == "\u{001B}" {
                inEscape = true
                currentSequence = "\u{001B}"
            } else {
                if visibleIndex >= count {
                    if !capturing {
                        capturing = true
                        if !pendingSequences.isEmpty {
                            result.append(pendingSequences)
                            pendingSequences.removeAll(keepingCapacity: true)
                        }
                    }
                    result.append(character)
                }
                visibleIndex += 1
            }
            index = line.index(after: index)
        }

        return capturing ? result : ""
    }
}

private struct ModalOverlay<Base: TUIView>: TUIView {
    let base: Base
    let modal: OverlayPresenter.ModalSnapshot

    var body: some TUIView {
        ZStack(alignment: .center) {
            base.foregroundColor(.brightBlack)
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
