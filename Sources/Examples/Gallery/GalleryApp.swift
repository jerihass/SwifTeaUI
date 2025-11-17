import SwifTeaCore
import SwifTeaUI

public struct GalleryApp: TUIApp {
    public init() {}
    public static var framesPerSecond: Int { 60 }
    public var body: some TUIScene { GalleryScene() }
}

struct GalleryScene: TUIScene {
    typealias Model = GalleryModel
    typealias Action = GalleryModel.Action

    var model: GalleryModel

    init(model: GalleryModel = GalleryModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: GalleryModel) -> some TUIView {
        model.makeView()
    }

    mutating func initializeEffects() {
        model.initializeEffects()
    }

    mutating func handleTerminalResize(from oldSize: TerminalSize, to newSize: TerminalSize) {
        model.handleTerminalResize(to: newSize)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        model.mapKeyToAction(key)
    }

    func shouldExit(for action: Action) -> Bool {
        model.shouldExit(for: action)
    }
}
