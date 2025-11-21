import Testing
import SwifTeaUI
@testable import GalleryExample

struct GallerySnapshotTests {

    @Test("Defaults to rendering the Counter section")
    func testCounterSectionSnapshot() {
        let snapshot = renderGallery()
        #expect(snapshot.contains("SwifTea Gallery"))
        #expect(snapshot.contains("Counter & State"))
    }

    @Test("Switching sections shows the Form view")
    func testFormSectionSnapshot() {
        let snapshot = renderGallery { model in
            model.update(action: .selectSection(.form))
        }
        #expect(snapshot.contains("Form & Focus"))
    }

    @Test("Table section renders when selected")
    func testTableSectionSnapshot() {
        let snapshot = renderGallery { model in
            model.update(action: .selectSection(.table))
        }
        #expect(snapshot.contains("Table Snapshot"))
    }

    private func renderGallery(
        configure: (inout GalleryModel) -> Void = { _ in }
    ) -> String {
        TerminalDimensions.withTemporarySize(TerminalSize(columns: 140, rows: 40)) {
            var model = GalleryModel()
            configure(&model)
            return model.makeView().render()
        }
    }
}
