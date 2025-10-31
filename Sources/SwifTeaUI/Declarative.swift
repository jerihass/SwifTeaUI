import SwifTeaCore

public protocol DeclarativeTUIView: TUIView {
    associatedtype Body: TUIView

    var body: Body { get }
}

public extension DeclarativeTUIView {
    func render() -> String {
        body.render()
    }
}
