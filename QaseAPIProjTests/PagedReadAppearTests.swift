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

    // Ловит: до завершения первой загрузки модель сообщает «загружено» — экран мелькает пустым состоянием.
    @Test func firstLoadIsPendingUntilItCompletes() async {
        let control = AppearFetchControl(suspendFirstCall: true)
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "appear")) { _, _ in
            await control.fetch()
        }
        #expect(!model.hasAppeared && model.showsSkeleton)
        let task = Task { await model.appear() }
        await waitForCondition { control.calls == 1 }
        #expect(model.isLoading && !model.hasAppeared)
        #expect(model.showsSkeleton)
        control.releaseFirstCall()
        await task.value
        #expect(model.hasAppeared)
        #expect(!model.showsSkeleton)
    }

    // Ловит: отменённая первая загрузка снимает ожидание — экран показывает пустое состояние
    // вместо скелетона.
    @Test func cancelledFirstLoadKeepsThePendingState() async {
        let control = AppearFetchControl(suspendFirstCall: true)
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "appear")) { _, _ in
            await control.fetch()
        }
        let task = Task { await model.appear() }
        await waitForCondition { control.calls == 1 }
        task.cancel()
        control.releaseFirstCall()
        await task.value
        #expect(!model.hasAppeared)
        await model.appear()
        #expect(model.hasAppeared)
    }

    // Ловит: ошибка первой загрузки оставляет скелетон вместо карточки ошибки.
    @Test func failedFirstLoadEndsThePendingState() async {
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "appear")) { _, _ in
            throw URLError(.notConnectedToInternet)
        }
        await model.appear()
        #expect(model.hasAppeared)
        #expect(model.errorMessage != nil && model.items.isEmpty)
        #expect(!model.showsSkeleton)
    }

    // Ловит: кеш показывается только после ответа — на время запроса экран с данными закрыт скелетоном.
    @Test func cachedItemsAreShownWhileTheFirstLoadIsPending() async {
        let control = AppearFetchControl(suspendFirstCall: true)
        let cached = CaseSummary(id: 7, title: "Cached", description: nil, priority: nil, automation: nil)
        let model = PagedReadViewModel<CaseSummary>(
            session: SessionContext(ownerID: "appear"),
            cached: { _ in [cached] }
        ) { _, _ in await control.fetch() }
        let task = Task { await model.appear() }
        await waitForCondition { control.calls == 1 }
        #expect(model.items.map(\.id) == [7])
        #expect(!model.showsSkeleton)
        control.releaseFirstCall()
        await task.value
    }

    // Ловит: после выхода из аккаунта модель больше не грузит данные, а скелетон висит вечно.
    @Test func sessionInvalidationEndsThePendingState() {
        let session = SessionContext(ownerID: "appear")
        let model = PagedReadViewModel<CaseSummary>(session: session) { _, _ in
            QaseAPIListResult(total: 0, filtered: 0, count: 0, entities: [])
        }
        session.invalidate()
        #expect(model.hasAppeared)
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
