import Testing

@testable import SwifTeaUI

struct PreviewTests {

    @Test("View previews honor terminal size overrides")
    func testViewPreviewRespectsTerminalSizeOverride() {
        let preview = TUIViewPreview(
            "Size Check",
            size: TerminalSize(columns: 42, rows: 5)
        ) {
            Text("Cols: \(TerminalDimensions.current.columns)")
        }

        let rendered = preview.render()
        #expect(rendered.contains("Cols: 42"))
    }

    @Test("Scene previews render the scene view without runtime loop")
    func testScenePreviewRendersSceneContent() {
        let preview = TUIViewPreview.scene("Mock Scene") {
            MockScene(model: .init(value: 7))
        }

        let rendered = preview.render()
        #expect(rendered.contains("Model: 7"))
    }

    @Test("PreviewBuilder flattens mixed expressions")
    func testPreviewBuilderFlattening() {
        struct BuilderHarness {
            static let includeExtra = true

            @PreviewBuilder
            static var previews: [TUIViewPreview] {
                TUIViewPreview("Primary") { Text("A") }
                if includeExtra {
                    TUIViewPreview("Secondary") { Text("B") }
                }
            }
        }

        let names = BuilderHarness.previews.map(\.name)
        #expect(names == ["Primary", "Secondary"])
    }
}

private struct MockScene: TUIScene {
    struct Model {
        var value: Int
    }

    enum Action: Sendable {
        case none
    }
    typealias Content = Text

    var model: Model

    mutating func update(action: Action) {}

    func view(model: Model) -> Text {
        Text("Model: \(model.value)")
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? { nil }

    func shouldExit(for action: Action) -> Bool {
        false
    }
}
