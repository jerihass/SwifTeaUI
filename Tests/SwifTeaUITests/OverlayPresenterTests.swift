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
}
