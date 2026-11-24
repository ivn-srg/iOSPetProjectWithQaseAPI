import Foundation
@testable import QaseAPIProj
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
struct PagedReadViewModelTests {
    @Test("A late response for a previous search never replaces the new results")
    func staleSearch() async {
        let control = SearchResponseControl()
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "search")) { query, _ in
            await control.response(query: query)
        }
        model.query = "old"
        let first = Task { await model.reload() }
        await control.waitUntilSuspended()
        model.query = "new"
        await model.reload()
        control.resumeOld()
        await first.value
        #expect(model.items.map(\.title) == ["new"])
        #expect(model.isLoading == false)
    }

    // Ловит: Retry после сбоя догрузки перезагружает список с первой страницы (offset 0)
    // или сбой страницы очищает уже загруженные элементы.
    @Test func retryAfterFailedPageRequestsTheSamePageAndKeepsLoadedItems() async {
        let script = PageScript(failingCalls: [2])
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "page")) { _, offset in
            try script.page(offset: offset)
        }
        await model.reload()
        await model.loadMore()
        #expect(model.items.map(\.id) == [1, 2])
        #expect(model.errorMessage != nil)
        await model.retry()
        #expect(script.offsets == [0, 2, 2])
        #expect(model.items.map(\.id) == [1, 2, 3, 4])
        #expect(model.errorMessage == nil)
    }

    // Проверяет: после сбоя первой загрузки `retry()` загружает первую страницу.
    // Мутация «`retry()` всегда догружает» здесь эквивалентна (неудачный `reload` уже обнулил offset) —
    // её ловит `failedRefreshAfterPageFailureMakesRetryReloadFromStart` через показ кеша.
    @Test func retryAfterFailedFirstLoadStartsFromTheFirstPage() async {
        let script = PageScript(failingCalls: [1])
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "page")) { _, offset in
            try script.page(offset: offset)
        }
        await model.reload()
        #expect(model.items.isEmpty && model.errorMessage != nil)
        await model.retry()
        #expect(script.offsets == [0, 0])
        #expect(model.items.map(\.id) == [1, 2])
    }

    // Ловит: признак сбоя страницы не сбрасывается новой загрузкой — после неудачного обновления
    // с показом кеша Retry молча ничего не делает (догрузка запрещена при `usingCache`).
    @Test func failedRefreshAfterPageFailureMakesRetryReloadFromStart() async {
        let script = PageScript(failingCalls: [2, 3])
        let model = PagedReadViewModel<CaseSummary>(
            session: SessionContext(ownerID: "page"),
            cached: { _ in [Self.item(1, "Case 1")] }
        ) { _, offset in try script.page(offset: offset) }
        await model.reload()
        await model.loadMore()
        await model.reload()
        #expect(model.usingCache)
        await model.retry()
        #expect(script.offsets == [0, 2, 0, 0])
        #expect(!model.usingCache)
        #expect(model.items.map(\.id) == [1, 2])
    }

    // Ловит: признак сбоя страницы не сбрасывается успешной загрузкой — следующий `retry()`
    // догружает страницу вместо загрузки с начала.
    @Test func successfulReloadClearsThePageFailure() async {
        let script = PageScript(failingCalls: [2])
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "page")) { _, offset in
            try script.page(offset: offset)
        }
        await model.reload()
        await model.loadMore()
        await model.reload()
        #expect(model.errorMessage == nil)
        await model.retry()
        #expect(script.offsets == [0, 2, 0, 0])
    }

    @Test("Offline search is restricted to cached matching cases and disables pagination")
    func cachedSearch() async {
        let model = PagedReadViewModel<CaseSummary>(
            session: SessionContext(ownerID: "cache"),
            cached: { query in
                [Self.item(1, "Login"), Self.item(2, "Project")]
                    .filter { $0.title.localizedCaseInsensitiveContains(query) }
            }
        ) { _, _ in throw URLError(.notConnectedToInternet) }
        model.query = "login"
        await model.reload()
        #expect(model.items.map(\.id) == [1])
        #expect(model.usingCache)
        #expect(!model.hasMore)
        #expect(model.errorMessage != nil)
    }

    @Test("Pagination advances by the server page count while deduplicating entity IDs")
    func pagination() async {
        var offsets: [Int] = []
        let model = PagedReadViewModel<CaseSummary>(session: SessionContext(ownerID: "pages")) { _, offset in
            offsets.append(offset)
            let items = offset == 0 ? [Self.item(1, "First"), Self.item(2, "Second")] : [
                Self.item(2, "Second"),
                Self.item(3, "Third")
            ]
            return QaseAPIListResult(total: 4, filtered: 4, count: 2, entities: items)
        }
        await model.reload()
        await model.loadMore()
        #expect(offsets == [0, 2])
        #expect(model.items.map(\.id) == [1, 2, 3])
        #expect(!model.hasMore)
    }

    @Test("A response from the previous session is rejected")
    func staleSession() async {
        let session = SessionContext(ownerID: "old")
        let model = PagedReadViewModel<CaseSummary>(session: session) { _, _ in
            session.invalidate()
            session.activate(ownerID: "new")
            return QaseAPIListResult(total: 1, filtered: 1, count: 1, entities: [Self.item(1, "Old owner")])
        }
        await model.reload()
        #expect(model.items.isEmpty)
        #expect(model.errorMessage == nil)
    }

    private static func item(_ id: Int, _ title: String) -> CaseSummary {
        CaseSummary(id: id, title: title, description: nil, priority: nil, automation: nil)
    }
}

@MainActor
private final class SearchResponseControl {
    private var oldResponse: CheckedContinuation<QaseAPIListResult<CaseSummary>, Never>?

    func response(query: String) async -> QaseAPIListResult<CaseSummary> {
        if query == "old" {
            return await withCheckedContinuation { continuation in
                oldResponse = continuation
            }
        }
        return page(title: "new")
    }

    /// Ограниченное ожидание: без приостановки тест падает по `waitForCondition`, а не висит.
    func waitUntilSuspended() async {
        await waitForCondition { oldResponse != nil }
    }

    func resumeOld() {
        oldResponse?.resume(returning: page(title: "old"))
        oldResponse = nil
    }

    private func page(title: String) -> QaseAPIListResult<CaseSummary> {
        QaseAPIListResult(
            total: 1,
            filtered: 1,
            count: 1,
            entities: [CaseSummary(id: 1, title: title, description: nil, priority: nil, automation: nil)]
        )
    }
}

/// Две страницы по два кейса (`total` 4); вызовы с номерами из `failingCalls` падают без сети.
@MainActor
private final class PageScript {
    private let failingCalls: Set<Int>
    private(set) var offsets: [Int] = []

    init(failingCalls: Set<Int>) { self.failingCalls = failingCalls }

    func page(offset: Int) throws -> QaseAPIListResult<CaseSummary> {
        offsets.append(offset)
        if failingCalls.contains(offsets.count) { throw URLError(.notConnectedToInternet) }
        let ids = [offset + 1, offset + 2]
        let entities = ids.map {
            CaseSummary(id: $0, title: "Case \($0)", description: nil, priority: nil, automation: nil)
        }
        return QaseAPIListResult(total: 4, filtered: 4, count: entities.count, entities: entities)
    }
}
