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
        let network = emptyListNetwork()
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
        let network = emptyListNetwork()
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
        let network = emptyListNetwork()
        network.holds = { _ in false }
        let model = TestDependencies.entities(projectCode: "DEMO", network: network, session: session)
        #expect(!model.levelIsEmpty)
        await model.reload()
        #expect(model.levelIsEmpty)
        network.holds = { _ in true }
        let reload = Task { await model.reload() }
        await waitForCondition { network.pending > 0 }
        #expect(model.isLoading)
        #expect(model.levelIsEmpty)
        network.holds = { _ in false }
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

/// Сеть списка на общем ядре: каждый запрос ждёт `releaseAll()` и возвращает пустую страницу.
@MainActor
private func emptyListNetwork() -> ScriptedNetwork {
    let network = ScriptedNetwork(respond: ScriptedNetwork.body(
        #"{"status": true, "result": {"total": 0, "filtered": 0, "count": 0, "entities": []}}"#
    ))
    network.holds = { _ in true }
    return network
}
