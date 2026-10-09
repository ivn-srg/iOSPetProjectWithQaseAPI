import Foundation
import RealmSwift
import Testing
@testable import QaseAPIProj

@Suite @MainActor
struct FormParentPickerTests {
    @Test func pagesWithoutTotalsLoadUntilShortPageAndDeduplicate() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = FormCatalogNetwork()
        network.pages = [0: (1...50).map { suite($0, "Suite \($0)") }, 50: [suite(50, "Duplicate"), suite(51, "Last")]]
        let model = SuitePickerViewModel(projectCode: "A", selectedID: 0, network: network, dao: dao, session: session)
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
        #expect(dao.replaceSuiteCatalog([suite(1, "Auth"), suite(2, "Payments"), suite(3, "Smoke", parent: 1), suite(4, "Smoke", parent: 2)], projectCode: "A", stamp: session.capture()))
        let model = SuitePickerViewModel(projectCode: "A", selectedID: 3, projectTitle: "Demo", dao: dao, session: session)
        #expect(model.pathTitle(to: 3) == "Demo › Auth › Smoke")
        #expect(model.pathTitle(to: 4) == "Demo › Payments › Smoke")
        #expect(model.ancestorTitle(to: 3) == "Demo › Auth")
        model.query = "Payments"
        #expect(model.filteredSuites.map(\.id) == [2, 4])
        model.cancel()
        #expect(model.selectedID == 3)
    }

    @Test func missingParentsAndCyclesReturnSafeIdentifiableFallback() {
        let values = [suite(1, "Cycle A", parent: 2), suite(2, "Cycle B", parent: 1), suite(3, "Orphan", parent: 99)]
        #expect(SuiteCatalogLoader.breadcrumbs(catalog: values, suiteID: 1) == nil)
        #expect(SuiteCatalogLoader.breadcrumbs(catalog: values, suiteID: 3) == nil)
        #expect(SuiteCatalogLoader.breadcrumbs(catalog: values, suiteID: nil)?.map(\.id) == [nil])
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        #expect(dao.replaceSuiteCatalog(values, projectCode: "A", stamp: session.capture()))
        let model = SuitePickerViewModel(projectCode: "A", dao: dao, session: session)
        #expect(model.pathTitle(to: 1).contains("#1"))
        #expect(model.pathTitle(to: 3).contains("#3"))
    }

    @Test func cancelDuringResponseKeepsCachedCatalogUntouched() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        #expect(dao.replaceSuiteCatalog([suite(99, "Saved")], projectCode: "A", stamp: session.capture()))
        let network = FormCatalogNetwork()
        network.pages = [0: [suite(1, "Late")]]
        let model = SuitePickerViewModel(projectCode: "A", selectedID: 99, network: network, dao: dao, session: session)
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
        let network = FormCatalogNetwork()
        network.error = .noInternetConnection
        let model = SuitePickerViewModel(projectCode: "A", network: network, dao: dao, session: session)
        await model.load()
        #expect(!model.catalogComplete && model.errorMessage != nil)
        #expect(model.catalog.map(\.id) == [99])
        #expect(!dao.hasRepositoryCatalog(projectCode: "A"))
    }

    @Test func stalledFullPageFailsWithoutReplacingCache() async {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = FormCatalogNetwork()
        let page = (1...50).map { suite($0, "Suite") }
        network.pages = [0: page, 50: page]
        let model = SuitePickerViewModel(projectCode: "A", network: network, dao: dao, session: session)
        await model.load()
        #expect(network.offsets == [0, 50])
        #expect(model.errorMessage != nil && !model.catalogComplete)
        #expect(!dao.hasRepositoryCatalog(projectCode: "A"))
    }

    @Test func staleOwnerCannotCacheResponseUnderAnotherOwner() async {
        let session = SessionContext(ownerID: "old")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = FormCatalogNetwork()
        network.pages = [0: [suite(1, "Old")]]
        let model = SuitePickerViewModel(projectCode: "A", network: network, dao: dao, session: session)
        network.beforeResponse = { session.activate(ownerID: "new") }
        await model.load()
        #expect(!model.catalogComplete && model.catalog.isEmpty)
        #expect(!dao.hasRepositoryCatalog(projectCode: "A"))
    }

    private func suite(_ id: Int, _ title: String, parent: Int? = nil) -> TestListEntity {
        TestListEntity(isSuite: true, id: id, title: title, description: nil, parentId: parent, casesCount: nil)
    }
}

private final class FormCatalogNetwork: NetworkManager {
    var pages: [Int: [TestListEntity]] = [:]
    var offsets: [Int] = []
    var error: API.NetError?
    var beforeResponse: (() -> Void)?

    func performRequest<T: Decodable>(for operation: API.Operation, pathParameters: [String: String], queryItems: [URLQueryItem], with data: Encodable?, modelType: T.Type) async throws(API.NetError) -> T {
        let offset = Int(queryItems.first { $0.name == "offset" }?.value ?? "0") ?? 0
        offsets.append(offset)
        beforeResponse?()
        if let error { throw error }
        let response = FormCatalogResponse(status: true, result: QaseAPIListResult(total: nil, filtered: nil, count: nil, entities: pages[offset] ?? []))
        do { return try API.decodeResponse(from: JSONEncoder().encode(response), as: modelType) }
        catch let error as API.NetError { throw error }
        catch { throw .serializationError("Fixture encoding failed") }
    }
    func performRequest<T: Decodable>(with data: Encodable?, from urlString: URL?, method: API.HTTPMethod, modelType: T.Type) async throws(API.NetError) -> T { throw .invalidURL }
    func performMultipartRequest<T: Decodable>(for operation: API.Operation, pathParameters: [String: String], files: [API.UploadFile], modelType: T.Type) async throws(API.NetError) -> T { throw .invalidURL }
    func composeURL(for method: API.Endpoint, urlComponents: [String?]?, queryItems: [API.QueryParams: Int?]?) -> URL? { nil }
    func composeURL(for operation: API.Operation, pathParameters: [String: String], queryItems: [URLQueryItem]) -> URL? { API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems) }
    func auth(by token: String) async throws -> Bool { true }
}

private struct FormCatalogResponse: Encodable {
    let status: Bool
    let result: QaseAPIListResult<TestListEntity>
}
