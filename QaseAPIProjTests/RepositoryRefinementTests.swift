import Foundation
import RealmSwift
import Testing
@testable import QaseAPIProj

@Suite @MainActor
struct RepositoryRefinementTests {
    @Test func descriptionSurvivesBothCacheWritersAndExplicitNullClearsIt() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let described = try JSONDecoder().decode(ProjectSummary.self, from: Data(#"{"title":"A","code":"A","description":"Mobile"}"#.utf8))
        #expect(dao.saveProjectSummaries([described], stamp: session.capture()))
        let absent = try JSONDecoder().decode(Project.self, from: Data(#"{"title":"A","code":"A"}"#.utf8))
        #expect(dao.saveProjects([absent], stamp: session.capture()))
        #expect(dao.getProjects()?.first?.description == "Mobile")
        #expect(dao.getProjectSummaries().first?.description == "Mobile")
        let cleared = try JSONDecoder().decode(ProjectSummary.self, from: Data(#"{"title":"A","code":"A","description":null}"#.utf8))
        #expect(dao.saveProjectSummaries([cleared], stamp: session.capture()))
        #expect(dao.getProjects()?.first?.description == nil)
    }

    @Test func rootCreationDoesNotInventAParentID() {
        let session = SessionContext(ownerID: "owner")
        let model = CreateSuiteOrCaseViewModel(projectCode: "A", parentSuiteId: nil, session: session)
        #expect(model.creatingSuite.parentId == nil)
        #expect(model.creatingTestCase.suiteId == nil)
    }
}

@Suite @MainActor
struct RepositoryHierarchyTests {
    @Test func rootContainsSuitesAndLooseCasesWithSeparateIdentifiers() async throws {
        let session = SessionContext(ownerID: "root")
        let cache = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let model = TestEntitiesViewModel(projectCode: "DEMO", network: APIMockManager.shared, dao: cache, session: session)
        await model.reload()
        #expect(model.suiteError == nil && model.caseError == nil)
        #expect(model.childSuites.contains { $0.id == 81 })
        #expect(model.cases.contains { $0.id == 81 })
        #expect(RepositoryItemReference(projectCode: "DEMO", id: 81, isSuite: true).key != RepositoryItemReference(projectCode: "DEMO", id: 81, isSuite: false).key)
        #expect(model.cases.allSatisfy { $0.parentId == nil })
        #expect(model.path(to: 86)?.map(\.id) == [nil, 81, 82, 86])
        let child = TestEntitiesViewModel(projectCode: "DEMO", parentSuite: ParentSuite(id: 81, title: "Suite", codeOfProject: "DEMO"), network: APIMockManager.shared, dao: cache, session: session)
        await child.reload()
        #expect(child.childSuites.contains { $0.id == 82 })
        #expect(child.cases.allSatisfy { $0.parentId == 81 })
    }

    @Test func completeLevelReplacementDoesNotResurrectRemovedMembership() {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let a = TestListEntity(isSuite: false, id: 7, title: "Moved", description: nil, parentId: 1, casesCount: nil)
        let b = TestListEntity(isSuite: false, id: 8, title: "Other level", description: nil, parentId: 2, casesCount: nil)
        #expect(cache.saveTestEntities([a,b], projectCode: "A", stamp: session.capture()))
        #expect(cache.replaceRepositoryCases([], location: .init(projectCode: "A", suiteID: 1), stamp: session.capture()))
        #expect(cache.getAllCachedCases(projectCode: "A").map(\.id) == [8])
        #expect(!cache.replaceRepositoryCases([], location: .init(projectCode: "A", suiteID: nil), stamp: SessionStamp(ownerID: "wrong", generation: 0)))
        #expect(cache.getAllCachedCases(projectCode: "A").count == 1)
    }

    @Test func malformedParentsDoNotLoop() {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let values = [TestListEntity(isSuite: true, id: 1, title: "A", description: nil, parentId: 2, casesCount: nil), TestListEntity(isSuite: true, id: 2, title: "B", description: nil, parentId: 1, casesCount: nil)]
        #expect(cache.replaceSuiteCatalog(values, projectCode: "A", stamp: session.capture()))
        let model = TestEntitiesViewModel(projectCode: "A", dao: cache, session: session)
        #expect(model.path(to: 1) == nil)
        #expect(model.path(to: 99) == nil)
    }

    @Test func migrationFromFourPreservesOwnerAndMetrics() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let config = Realm.Configuration(fileURL: folder.appendingPathComponent("cache.realm"), schemaVersion: 4, objectTypes: RealmManager.cacheObjectTypes)
        let session = SessionContext(ownerID: "migration")
        try autoreleasepool {
            let cache = RealmManager(configuration: config, session: session)
            #expect(cache.saveProjectSummaries([.init(title: "A", code: "A", metrics: .init(cases: 42))], stamp: session.capture()))
        }
        let migrated = RealmManager(configuration: RealmManager.migratedConfiguration(config), session: session)
        #expect(migrated.initializationError == nil)
        #expect(migrated.getProjectSummaries().first?.metrics.cases == 42)
        let described = ProjectSummary(title: "A", code: "A", description: "After upgrade")
        #expect(migrated.saveProjectSummaries([described], stamp: session.capture()))
        #expect(migrated.getProjects()?.first?.description == "After upgrade")
    }
}

@Suite @MainActor
struct RepositoryPaginationTests {
    @Test func locallyEmptyRootPageIsNotEndOfPagination() async {
        let session = SessionContext(ownerID: "pagination")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = LevelNetwork()
        let model = TestEntitiesViewModel(projectCode: "A", network: network, dao: dao, session: session)
        await model.reload()
        #expect(network.caseOffsets == [0,50])
        #expect(model.cases.map(\.id) == [51])
        #expect(model.caseCount == 1)
        #expect(dao.getAllCachedCases(projectCode: "A").count == 51)
    }

    @Test func staleOwnerCannotPublishHierarchy() async {
        let session = SessionContext(ownerID: "old")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = LevelNetwork()
        network.onRequest = { session.invalidate(); session.activate(ownerID: "new") }
        let model = TestEntitiesViewModel(projectCode: "A", network: network, dao: dao, session: session)
        await model.reload()
        #expect(model.cases.isEmpty && model.catalog.isEmpty)
        #expect(dao.getAllCachedCases(projectCode: "A").isEmpty)
    }

    @Test func rootCaseCreatedInDemoRemainsAtRoot() async throws {
        let session = SessionContext(ownerID: "create")
        let model = CreateSuiteOrCaseViewModel(projectCode: "DEMO", parentSuiteId: nil, network: APIMockManager.shared, session: session)
        model.creatingEntityIsSuite = false
        model.creatingTestCase.title = "Root fixture case"
        try await model.createNewEntity()
        let repository = HomeRepository(network: APIMockManager.shared, session: session)
        let page = try await repository.cases(projectCode: "DEMO", query: "Root fixture case")
        let created = try #require(page.entities.first)
        #expect(created.suiteID == nil)
        let _: SharedResponseModel = try await APIMockManager.shared.performRequest(for: .deleteCase, pathParameters: ["code":"DEMO", "id":String(created.id)], queryItems: [], with: nil, modelType: SharedResponseModel.self)
    }
}

private final class LevelNetwork: NetworkManager {
    var caseOffsets: [Int] = []
    var onRequest: (() -> Void)?
    func performRequest<T: Decodable>(for operation: API.Operation, pathParameters: [String:String], queryItems: [URLQueryItem], with data: Encodable?, modelType: T.Type) async throws(API.NetError) -> T {
        onRequest?()
        if operation == .getSuites {
            return try API.decodeResponse(from: Data(#"{"status":true,"result":{"total":0,"filtered":0,"count":0,"entities":[]}}"#.utf8), as: modelType)
        }
        let offset = Int(queryItems.first { $0.name == "offset" }?.value ?? "0") ?? 0
        caseOffsets.append(offset)
        let cases: [[String:Any]] = offset == 0 ? (1...50).map { ["id":$0,"title":"Nested", "suite_id":1] } : [["id":51,"title":"Root", "suite_id":NSNull()]]
        let object: [String:Any] = ["status":true,"result":["total":51,"filtered":51,"count":cases.count,"entities":cases]]
        do { return try API.decodeResponse(from: JSONSerialization.data(withJSONObject: object), as: modelType) }
        catch let error as API.NetError { throw error }
        catch { throw .otherNetworkError(error.localizedDescription) }
    }
    func performRequest<T: Decodable>(with data: Encodable?, from urlString: URL?, method: API.HTTPMethod, modelType: T.Type) async throws(API.NetError) -> T { throw .invalidURL }
    func performMultipartRequest<T: Decodable>(for operation: API.Operation, pathParameters: [String:String], files: [API.UploadFile], modelType: T.Type) async throws(API.NetError) -> T { throw .invalidURL }
    func composeURL(for method: API.Endpoint, urlComponents: [String?]?, queryItems: [API.QueryParams:Int?]?) -> URL? { nil }
    func composeURL(for operation: API.Operation, pathParameters: [String:String], queryItems: [URLQueryItem]) -> URL? { API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems) }
    func auth(by token: String) async throws -> Bool { true }
}

@Suite struct RepositoryRequestTests {
    @Test func clearingSuiteEncodesNullInsteadOfZeroOrOmission() throws {
        var item = TestCaseEntity.empty
        item.suiteId = nil
        let data = try JSONEncoder().encode(item.dictOfValues)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String:Any])
        #expect(object["suite_id"] is NSNull)
        item.suiteId = 81
        let nested = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(item.dictOfValues)) as? [String:Any])
        #expect(nested["suite_id"] as? Int == 81)
    }
}
