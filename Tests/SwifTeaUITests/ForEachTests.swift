import Testing

@testable import SwifTeaUI

private struct CountingView: TUIView {
    typealias Body = Never

    nonisolated(unsafe) static var renders = 0
    let value: Int

    var body: Never { fatalError("CountingView has no body") }

    func render() -> String {
        Self.renders += 1
        return "row \(value)"
    }
}

@Suite(.serialized)
struct ForEachTests {
    @Test("Diffing reuses cached renders for unchanged elements")
    func testForEachDiffingReuse() {
        ForEachCacheStore.shared.reset()
        CountingView.renders = 0
        let forEach = ForEach([1, 2, 3], id: \.self) { value in
            [CountingView(value: value)]
        }
        .diffing(key: "stable")

        _ = forEach.makeChildViews()
        #expect(CountingView.renders == 3)

        CountingView.renders = 0
        _ = forEach.makeChildViews()
        #expect(CountingView.renders == 0)
    }

    @Test("Diffing key change invalidates cache")
    func testDiffingKeyInvalidates() {
        ForEachCacheStore.shared.reset()
        CountingView.renders = 0
        let initial = ForEach([1, 2], id: \.self) { value in
            [CountingView(value: value)]
        }
        .diffing(key: "a")

        _ = initial.makeChildViews()
        #expect(CountingView.renders == 2)

        CountingView.renders = 0
        let updated = initial.diffing(key: "b")
        _ = updated.makeChildViews()
        #expect(CountingView.renders == 2)
    }

    @Test("Proposal changes invalidate cached renders")
    func testProposalInvalidates() {
        ForEachCacheStore.shared.reset()
        CountingView.renders = 0
        let forEach = ForEach([1, 2], id: \.self) { value in
            [CountingView(value: value)]
        }
        .diffing(key: "stable")

        _ = forEach.render(in: RenderContext(proposedSize: ProposedViewSize(width: 10)))
        #expect(CountingView.renders == 2)

        CountingView.renders = 0
        _ = forEach.render(in: RenderContext(proposedSize: ProposedViewSize(width: 12)))
        #expect(CountingView.renders == 2)
    }
}
