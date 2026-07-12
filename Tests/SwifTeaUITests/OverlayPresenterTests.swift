import Testing
@testable import SwifTeaUI

struct OverlayPresenterTests {

    @Test("Toast expires after ticking past its duration")
    func toastExpiration() {
        var presenter = OverlayPresenter()
        presenter.presentToast(duration: 1) {
            Text("Hello")
        }

        #expect(presenter.hasNotifications)
        presenter.tick(deltaTime: 0.5)
        #expect(presenter.hasNotifications)
        presenter.tick(deltaTime: 0.6)
        #expect(!presenter.hasNotifications)
    }

    @Test("Modal stack honors priority and dismiss")
    func modalPriority() {
        var presenter = OverlayPresenter()
        presenter.presentModal(priority: 1, title: "Low") {
            Text("Low")
        }
        presenter.presentModal(priority: 2, title: "High") {
            Text("High")
        }
        #expect(presenter.activeModal?.title == "High")
        presenter.dismissModal()
        #expect(presenter.activeModal?.title == "Low")
        presenter.dismissModal()
        #expect(!presenter.hasModal)
    }

    @Test("Toasts draw over existing content without wiping the row")
    func toastOverlaysContent() {
        var presenter = OverlayPresenter()
        presenter.presentToast(duration: 5) {
            Text("Toast")
        }

        let host = OverlayHost(
            presenter: presenter,
            content: {
                Group {
                    Text("Underlying content should remain visible")
                    Text("Second line")
                }
            }
        )

        let lines = host.render().splitLinesPreservingEmpty()
        #expect(lines.count >= 2)
        #expect(lines[0].contains("remain visible")) // keep tail of base line after overlay
    }

    @Test("Modal presets retain their colored black-backed presentation")
    func modalPresetCompatibility() {
        #expect(OverlayPresenter.ModalStyle.info.borderColor == .brightBlue)
        #expect(OverlayPresenter.ModalStyle.info.titleColor == .brightWhite)
        #expect(OverlayPresenter.ModalStyle.info.backgroundColor == .black)
        #expect(OverlayPresenter.ModalStyle.warning.backgroundColor == .black)
        #expect(OverlayPresenter.ModalStyle.critical.backgroundColor == .black)
    }

    @Test("Modal styles can preserve the native background without foreground colors")
    func nativeModalStyle() {
        var presenter = OverlayPresenter()
        presenter.presentModal(
            title: "Native",
            style: OverlayPresenter.ModalStyle(
                accentColor: nil,
                borderColor: nil,
                titleColor: nil,
                backgroundColor: nil
            )
        ) {
            Text("No application colors")
        }

        let rendered = OverlayHost(presenter: presenter) {
            Text("Underlying content")
        }.render()

        #expect(rendered.contains("Native"))
        #expect(rendered.contains("No application colors"))
        for code in foregroundAndBackgroundColorCodes {
            #expect(!rendered.contains(code))
        }
    }

    @Test("Modal styles apply an explicit custom background")
    func customModalBackground() {
        var presenter = OverlayPresenter()
        presenter.presentModal(
            style: OverlayPresenter.ModalStyle(
                accentColor: nil,
                borderColor: nil,
                titleColor: nil,
                backgroundColor: .brightBlue
            )
        ) {
            Text("Colored surface")
        }

        let rendered = OverlayHost(presenter: presenter) {
            Text("Underlying content")
        }.render()

        #expect(rendered.contains(ANSIColor.brightBlue.backgroundCode))
    }
}

private let foregroundAndBackgroundColorCodes = [
    ANSIColor.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white,
    .brightBlack, .brightRed, .brightGreen, .brightYellow, .brightBlue, .brightMagenta,
    .brightCyan, .brightWhite,
].flatMap { [$0.rawValue, $0.backgroundCode] }
