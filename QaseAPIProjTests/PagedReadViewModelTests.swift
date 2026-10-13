import Foundation
@testable import QaseAPIProj
import Testing

@MainActor
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
    private var suspendedWaiter: CheckedContinuation<Void, Never>?

    func response(query: String) async -> QaseAPIListResult<CaseSummary> {
        if query == "old" {
            return await withCheckedContinuation { continuation in
                oldResponse = continuation
                suspendedWaiter?.resume()
                suspendedWaiter = nil
            }
        }
        return page(title: "new")
    }

    func waitUntilSuspended() async {
        guard oldResponse == nil else { return }
        await withCheckedContinuation { suspendedWaiter = $0 }
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
