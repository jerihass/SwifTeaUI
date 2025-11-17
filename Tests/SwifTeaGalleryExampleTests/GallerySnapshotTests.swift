import Testing
import SwifTeaCore
@testable import GalleryExample

struct GallerySnapshotTests {

    @Test("Defaults to rendering the Notebook section")
    func testNotebookSectionSnapshot() {
        let snapshot = renderGallery()
        #expect(snapshot.contains("SwifTea Gallery"))
        #expect(snapshot.contains("SwifTea Notebook"))
    }

    @Test("Switching sections shows the Task Runner view")
    func testTaskRunnerSectionSnapshot() {
        let snapshot = renderGallery { model in
            model.update(action: .selectSection(.tasks))
        }
        #expect(snapshot.contains("SwifTea Task Runner"))
    }

    @Test("Package List section renders when selected")
    func testPackageListSectionSnapshot() {
        let snapshot = renderGallery { model in
            model.update(action: .selectSection(.packages))
        }
        #expect(snapshot.contains("Mint Package Dashboard"))
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
