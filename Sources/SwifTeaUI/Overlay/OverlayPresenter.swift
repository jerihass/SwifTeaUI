import Foundation

public struct OverlayPresenter {
    public enum Placement {
        case top
        case bottom
    }

    public struct ToastStyle {
        public var accentColor: ANSIColor
        public var backgroundColor: ANSIColor
        public var textColor: ANSIColor
        public var icon: String?

        public init(
            accentColor: ANSIColor,
            backgroundColor: ANSIColor,
            textColor: ANSIColor,
            icon: String?
        ) {
            self.accentColor = accentColor
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.icon = icon
        }

        public static let info = ToastStyle(
            accentColor: .brightCyan,
            backgroundColor: .brightBlack,
            textColor: .brightWhite,
            icon: "ℹ︎"
        )

        public static let success = ToastStyle(
            accentColor: .brightGreen,
            backgroundColor: .black,
            textColor: .brightGreen,
            icon: "✓"
        )

        public static let warning = ToastStyle(
            accentColor: .brightYellow,
            backgroundColor: .black,
            textColor: .brightYellow,
            icon: "⚠︎"
        )

        public static let error = ToastStyle(
            accentColor: .brightRed,
            backgroundColor: .black,
            textColor: .brightRed,
            icon: "!"
        )
    }

    public struct ModalStyle {
        public var accentColor: ANSIColor
        public var borderColor: ANSIColor
        public var titleColor: ANSIColor

        public init(
            accentColor: ANSIColor,
            borderColor: ANSIColor,
            titleColor: ANSIColor
        ) {
            self.accentColor = accentColor
            self.borderColor = borderColor
            self.titleColor = titleColor
        }

        public static let info = ModalStyle(
            accentColor: .brightCyan,
            borderColor: .brightBlue,
            titleColor: .brightWhite
        )

        public static let warning = ModalStyle(
            accentColor: .brightYellow,
            borderColor: .brightYellow,
            titleColor: .brightWhite
        )

        public static let critical = ModalStyle(
            accentColor: .brightRed,
            borderColor: .brightRed,
            titleColor: .brightWhite
        )
    }

    public struct ToastSnapshot: Identifiable {
        public var id: UUID
        public var style: ToastStyle
        public var view: AnyTUIView
    }

    public struct ModalSnapshot {
        public var id: UUID
        public var style: ModalStyle
        public var title: String?
        public var view: AnyTUIView
    }

    private struct Toast {
        var id: UUID
        var placement: Placement
        var remaining: TimeInterval
        var style: ToastStyle
        var view: AnyTUIView

        func snapshot() -> ToastSnapshot {
            ToastSnapshot(id: id, style: style, view: view)
        }
    }

private struct Modal {
    var id: UUID
    var priority: Int
    var title: String?
    var style: ModalStyle
    var view: AnyTUIView

    func snapshot() -> ModalSnapshot {
        ModalSnapshot(id: id, style: style, title: title, view: view)
    }
}

    private var toasts: [Toast] = []
    private var modals: [Modal] = []

    public init() {}

    public var hasNotifications: Bool { !toasts.isEmpty }
    public var hasModal: Bool { !modals.isEmpty }

    public var topToasts: [ToastSnapshot] {
        toasts.filter { $0.placement == .top }.map { $0.snapshot() }
    }

    public var bottomToasts: [ToastSnapshot] {
        toasts.filter { $0.placement == .bottom }.map { $0.snapshot() }
    }

    public var activeModal: ModalSnapshot? {
        modals.max(by: { a, b in
            if a.priority == b.priority {
                return false
            }
            return a.priority < b.priority
        })?.snapshot()
    }

    public mutating func presentToast<T: TUIView>(
        id: UUID = UUID(),
        placement: Placement = .bottom,
        duration: TimeInterval = 3,
        style: ToastStyle = .info,
        content: () -> T
    ) {
        let rendered = AnyTUIView(ToastView(style: style, content: AnyTUIView(content())))
        let toast = Toast(
            id: id,
            placement: placement,
            remaining: max(0.5, duration),
            style: style,
            view: rendered
        )
        toasts.append(toast)
    }

    public mutating func tick(deltaTime: TimeInterval) {
        guard deltaTime > 0, !toasts.isEmpty else { return }
        for index in toasts.indices {
            toasts[index].remaining -= deltaTime
        }
        toasts.removeAll { $0.remaining <= 0 }
    }

    public mutating func clearToasts() {
        toasts.removeAll()
    }

    public mutating func presentModal<T: TUIView>(
        id: UUID = UUID(),
        priority: Int = 0,
        title: String? = nil,
        style: ModalStyle = .info,
        content: () -> T
    ) {
        let rendered = AnyTUIView(content())
        modals.removeAll { $0.id == id }
        modals.append(
            Modal(
                id: id,
                priority: priority,
                title: title,
                style: style,
                view: rendered
            )
        )
    }

    public mutating func dismissModal(id: UUID? = nil) {
        guard !modals.isEmpty else { return }
        if let id {
            modals.removeAll { $0.id == id }
        } else {
            _ = modals.popLast()
        }
    }

    public mutating func clearAll() {
        toasts.removeAll()
        modals.removeAll()
    }
}

private struct ToastView: TUIView {
    let style: OverlayPresenter.ToastStyle
    let content: AnyTUIView

    var body: some TUIView {
        Border(
            padding: 1,
            color: style.accentColor,
            background: style.backgroundColor,
            HStack(spacing: 1, horizontalAlignment: .leading, verticalAlignment: .center) {
                if let icon = style.icon {
                    Text(icon)
                        .foregroundColor(style.accentColor)
                        .bold()
                }
                content
            }
        )
    }
}
