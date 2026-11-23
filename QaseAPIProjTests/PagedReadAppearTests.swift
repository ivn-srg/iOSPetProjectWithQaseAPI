import Foundation
@testable import QaseAPIProj
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
struct PagedReadAppearTests {
    @Test("A cancelled first load is retried on the next appearance")
    func cancelledFirstLoadIsRetried() async {
        let control = AppearFetchControl(suspendFirstCall: true)
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "appear")) { _, _ in
            await control.fetch()
        }
        let task = Task { await model.appear() }
        await waitForCondition { control.calls == 1 }
        task.cancel()
        control.releaseFirstCall()
        await task.value
        await model.appear()
        #expect(control.calls == 2)
        #expect(model.items.map(\.id) == [1])
        await model.appear()
        #expect(control.calls == 2)
    }

    @Test("A completed first load is not repeated on the next appearance")
    func completedFirstLoadIsNotRepeated() async {
        let control = AppearFetchControl(suspendFirstCall: false)
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "appear")) { _, _ in
            await control.fetch()
        }
        await model.appear()
        await model.appear()
        #expect(control.calls == 1)
        #expect(model.items.map(\.id) == [1])
    }
}

@MainActor
private final class AppearFetchControl {
    private(set) var calls = 0
    private let suspendFirstCall: Bool
    private var pending: CheckedContinuation<Void, Never>?

    init(suspendFirstCall: Bool) { self.suspendFirstCall = suspendFirstCall }

    func fetch() async -> QaseAPIListResult<CaseSummary> {
        calls += 1
        if calls == 1, suspendFirstCall {
            await withCheckedContinuation { pending = $0 }
        }
        return QaseAPIListResult(
            total: 1,
            filtered: 1,
            count: 1,
            entities: [CaseSummary(id: 1, title: "Case", description: nil, priority: nil, automation: nil)]
        )
    }

    func releaseFirstCall() {
        pending?.resume()
        pending = nil
    }
}
