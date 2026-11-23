import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

/// Поиск Repository не мигает «No search results» в окно debounce,
/// а фокус поля применяется один раз на запрос.
@Suite(.timeLimit(.minutes(1))) @MainActor
struct RepositorySearchStateTests {
    @Test func typingShowsLoadingAndHidesStaleLoadMoreUntilResultsArrive() async {
        let session = SessionContext(ownerID: "owner")
        let network = SuspendingListNetwork()
        let model = TestDependencies.entities(projectCode: "DEMO", network: network, session: session)
        model.query = "a"
        let search = Task { await model.search(reset: true) }
        await waitForCondition { network.pending > 0 }
        #expect(model.moreSearchSuites && model.moreSearchCases)
        model.query = "ab"
        model.queryChanged()
        #expect(model.searchLoading)
        #expect(!model.moreSearchSuites && !model.moreSearchCases)
        network.releaseAll()
        await search.value
        model.query = ""
        model.queryChanged()
        #expect(!model.searchLoading)
        // Отпускаем запросы, если отложенный поиск «ab» успел стартовать: задача не должна висеть.
        network.releaseAll()
    }

    @Test func searchThatExitsEarlyDoesNotLeaveSpinner() async {
        let session = SessionContext(ownerID: "owner")
        let network = SuspendingListNetwork()
        let model = TestDependencies.entities(projectCode: "DEMO", network: network, session: session)
        model.query = "a"
        model.queryChanged()
        #expect(model.searchLoading)
        // Запрос стёрт, а отложенный поиск всё равно стартует: индикатор не должен остаться навсегда.
        model.query = ""
        await model.search(reset: true)
        #expect(!model.searchLoading)
    }

    @Test func emptyLevelCardSurvivesReloadInsteadOfFlickering() async {
        let session = SessionContext(ownerID: "owner")
        let network = SuspendingListNetwork()
        network.holdsRequests = false
        let model = TestDependencies.entities(projectCode: "DEMO", network: network, session: session)
        #expect(!model.levelIsEmpty)
        await model.reload()
        #expect(model.levelIsEmpty)
        network.holdsRequests = true
        let reload = Task { await model.reload() }
        await waitForCondition { network.pending > 0 }
        #expect(model.isLoading)
        #expect(model.levelIsEmpty)
        network.holdsRequests = false
        network.releaseAll()
        await reload.value
        #expect(model.levelIsEmpty)
    }

    @Test func searchFocusRequestIsConsumedOncePerRequest() {
        let session = SessionContext(ownerID: "owner")
        let model = TestDependencies.entities(projectCode: "DEMO", session: session)
        #expect(!model.consumeSearchFocusRequest())
        model.requestSearchFocus()
        #expect(model.consumeSearchFocusRequest())
        // Возврат на экран без нового запроса фокус не поднимает.
        #expect(!model.consumeSearchFocusRequest())
        model.requestSearchFocus()
        model.requestSearchFocus()
        #expect(model.consumeSearchFocusRequest())
        #expect(!model.consumeSearchFocusRequest())
    }
}

/// Запрос ждёт `releaseAll()` (если `holdsRequests`) и возвращает пустую страницу.
@MainActor
private final class SuspendingListNetwork: NetworkManager {
    var holdsRequests = true
    private var waiting: [CheckedContinuation<Void, Never>] = []
    var pending: Int { waiting.count }

    func releaseAll() {
        let continuations = waiting
        waiting = []
        continuations.forEach { $0.resume() }
    }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        if holdsRequests { await withCheckedContinuation { waiting.append($0) } }
        let body = #"{"status": true, "result": {"total": 0, "filtered": 0, "count": 0, "entities": []}}"#
        return try API.decodeResponse(from: Data(body.utf8), as: modelType)
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    func auth(by token: String) async throws -> Bool { true }
}
