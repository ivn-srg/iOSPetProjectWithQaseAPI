import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite @MainActor
struct FormParentPickerTests {
    @Test func pagesWithoutTotalsLoadUntilShortPageAndDeduplicate() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = catalogNetwork()
        network.respond = catalogPages([
            0: (1 ... 50).map { suite($0, "Suite \($0)") },
            50: [suite(50, "Duplicate"), suite(51, "Last")]
        ])
        let model = TestDependencies.picker(
            projectCode: "A",
            selectedID: 0,
            network: network,
            dao: dao,
            session: session
        )
        await model.load()
        #expect(network.offsets == [0, 50])
        #expect(model.catalog.count == 51 && model.catalogComplete)
        #expect(dao.hasRepositoryCatalog(projectCode: "A"))
        #expect(model.selectedID == nil)
        #expect(model.catalog.first { $0.id == 50 }?.title == "Suite 50")
    }

    @Test func duplicateNamesHaveDistinctPathsAndSearchMatchesAncestors() {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        #expect(dao.replaceSuiteCatalog(
            [suite(1, "Auth"), suite(2, "Payments"), suite(3, "Smoke", parent: 1), suite(
                4,
                "Smoke",
                parent: 2
            )],
            projectCode: "A",
            stamp: session.capture()
        ))
        let model = TestDependencies.picker(
            projectCode: "A",
            selectedID: 3,
            projectTitle: "Demo",
            dao: dao,
            session: session
        )
        #expect(model.pathTitle(to: 3) == "Demo › Auth › Smoke")
        #expect(model.pathTitle(to: 4) == "Demo › Payments › Smoke")
        #expect(model.ancestorTitle(to: 3) == "Demo › Auth")
        model.query = "Payments"
        #expect(model.filteredSuites.map(\.id) == [2, 4])
        model.cancel()
        #expect(model.selectedID == 3)
    }

    @Test func missingParentsAndCyclesReturnSafeIdentifiableFallback() {
        let values = [
            suite(1, "Cycle A", parent: 2),
            suite(2, "Cycle B", parent: 1),
            suite(3, "Orphan", parent: 99)
        ]
        #expect(SuiteCatalogLoader.breadcrumbs(catalog: values, suiteID: 1) == nil)
        #expect(SuiteCatalogLoader.breadcrumbs(catalog: values, suiteID: 3) == nil)
        #expect(SuiteCatalogLoader.breadcrumbs(catalog: values, suiteID: nil)?.map(\.id) == [nil])
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        #expect(dao.replaceSuiteCatalog(values, projectCode: "A", stamp: session.capture()))
        let model = TestDependencies.picker(projectCode: "A", dao: dao, session: session)
        #expect(model.pathTitle(to: 1).contains("#1"))
        #expect(model.pathTitle(to: 3).contains("#3"))
    }

    @Test func cancelDuringResponseKeepsCachedCatalogUntouched() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        #expect(dao.replaceSuiteCatalog([suite(99, "Saved")], projectCode: "A", stamp: session.capture()))
        let network = catalogNetwork()
        network.respond = catalogPages([0: [suite(1, "Late")]])
        let model = TestDependencies.picker(
            projectCode: "A",
            selectedID: 99,
            network: network,
            dao: dao,
            session: session
        )
        network.beforeResponse = { model.cancel() }
        await model.load()
        #expect(model.catalog.map(\.id) == [99])
        #expect(dao.getAllCachedSuites(projectCode: "A").map(\.id) == [99])
        #expect(!model.isLoading && model.selectedID == 99)
    }

    @Test func incompleteCacheAndFailureAreNotACompleteEmptyCatalog() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        #expect(dao.saveTestEntities([suite(99, "Partial")], projectCode: "A", stamp: session.capture()))
        let network = catalogNetwork()
        network.respond = ScriptedNetwork.failure(.noInternetConnection)
        let model = TestDependencies.picker(projectCode: "A", network: network, dao: dao, session: session)
        await model.load()
        #expect(!model.catalogComplete && model.errorMessage != nil)
        #expect(model.catalog.map(\.id) == [99])
        #expect(!dao.hasRepositoryCatalog(projectCode: "A"))
    }

    @Test func stalledFullPageFailsWithoutReplacingCache() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = catalogNetwork()
        let page = (1 ... 50).map { suite($0, "Suite") }
        network.respond = catalogPages([0: page, 50: page])
        let model = TestDependencies.picker(projectCode: "A", network: network, dao: dao, session: session)
        await model.load()
        #expect(network.offsets == [0, 50])
        #expect(model.errorMessage != nil && !model.catalogComplete)
        #expect(!dao.hasRepositoryCatalog(projectCode: "A"))
    }

    @Test func staleOwnerCannotCacheResponseUnderAnotherOwner() async {
        let session = SessionContext(ownerID: "old")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = catalogNetwork()
        network.respond = catalogPages([0: [suite(1, "Old")]])
        let model = TestDependencies.picker(projectCode: "A", network: network, dao: dao, session: session)
        network.beforeResponse = { session.activate(ownerID: "new") }
        await model.load()
        #expect(!model.catalogComplete && model.catalog.isEmpty)
        #expect(!dao.hasRepositoryCatalog(projectCode: "A"))
    }

    private func suite(_ id: Int, _ title: String, parent: Int? = nil) -> TestListEntity {
        TestListEntity(
            isSuite: true,
            id: id,
            title: title,
            description: nil,
            parentId: parent,
            casesCount: nil
        )
    }
}

/// Каталог наборов на общем ядре: страница по `offset` (нет параметра — 0), без итогов.
@MainActor
private func catalogNetwork() -> ScriptedNetwork {
    ScriptedNetwork(respond: catalogPages([:]))
}

private func catalogPages(_ pages: [Int: [TestListEntity]]) -> ScriptedNetwork.Responder {
    { request in
        let response = FormCatalogResponse(
            status: true,
            result: QaseAPIListResult(
                total: nil,
                filtered: nil,
                count: nil,
                entities: pages[request.offset ?? 0] ?? []
            )
        )
        do { return .success(try JSONEncoder().encode(response)) }
        catch { return .failure(.serializationError("Fixture encoding failed")) }
    }
}

private extension ScriptedNetwork {
    var offsets: [Int] { requests.map { $0.offset ?? 0 } }
}

private struct FormCatalogResponse: Encodable {
    let status: Bool
    let result: QaseAPIListResult<TestListEntity>
}
