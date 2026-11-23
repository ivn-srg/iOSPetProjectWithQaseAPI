import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite @MainActor
struct ProjectLifecycleTests {
    @Test func oldCreationDraftCannotAdoptAnotherOwner() async {
        let session = SessionContext(ownerID: "A")
        let network = LifecycleNetwork()
        let model = CreatingProjectViewModel(network: network, session: session)
        model.creatingProject.title = "Retained draft"
        model.creatingProject.code = "OLD"
        session.activate(ownerID: "B")
        do {
            try await model.createNewProject()
            Issue.record("A previous owner's form must fail before sending")
        } catch {
            #expect(network.requestedURLs.isEmpty)
        }
    }

    @Test func deletionUsesCapturedProjectAfterListReorders() async throws {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let network = LifecycleNetwork()
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        var a = Project()
        a.code = "A"
        a.title = "A"
        var b = Project()
        b.code = "B"
        b.title = "B"
        model.projects = [a, b]
        let confirmedProject = model.projects[0]
        model.projects.reverse()
        try await model.deleteProject(confirmedProject)
        #expect(network.requestedURLs.last?.path == "/v1/project/A")
        #expect(network.operations.last == .deleteProject)
        #expect(model.projects.map(\.code) == ["B"])
    }

    @Test func projectListRequestKeepsGetPathAndPaginationQuery() async throws {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":true,"result":{"total":0,"filtered":0,"count":0,"entities":[]}}"#
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        try await model.requestEntitiesData(place: .start)
        #expect(network.operations == [.getProjects])
        let url = try #require(network.requestedURLs.last)
        #expect(url.path == "/v1/project")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(query.first { $0.name == "limit" }?.value == "50")
        #expect(query.first { $0.name == "offset" }?.value == "0")
    }

    @Test func projectCreationPostsToTheProjectCollection() async throws {
        let session = SessionContext(ownerID: "owner")
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":true,"result":{"code":"NEW"}}"#
        let model = CreatingProjectViewModel(network: network, session: session)
        model.creatingProject.title = "New project"
        model.creatingProject.code = "NEW"
        try await model.createNewProject()
        #expect(network.operations == [.createProject])
        #expect(network.requestedURLs.last?.path == "/v1/project")
    }

    @Test func suiteAndCaseCreationUseTheirOwnOperationsAndProjectCode() async throws {
        let session = SessionContext(ownerID: "owner")
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":true,"result":{"id":1}}"#
        let model = TestDependencies.creator(projectCode: "A", network: network, session: session)
        model.creatingSuite.title = "Suite"
        model.creatingTestCase.title = "Case"
        model.creatingEntityIsSuite = true
        try await model.createNewEntity()
        #expect(network.operations == [.createSuite])
        #expect(network.requestedURLs.last?.path == "/v1/suite/A")
        model.creatingEntityIsSuite = false
        try await model.createNewEntity()
        #expect(network.operations == [.createSuite, .createCase])
        #expect(network.requestedURLs.last?.path == "/v1/case/A")
    }

    @Test func deletionUpdatesSelectionEvenIfRefreshIsOffline() async {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let a = ProjectSummary(title: "A", code: "A"), b = ProjectSummary(title: "B", code: "B")
        _ = cache.saveProjectSummaries([a, b], stamp: session.capture())
        let network = LifecycleNetwork()
        network.offline = true
        let repository = HomeRepository(network: network, dao: cache, session: session)
        let store = SelectedProjectStore(
            repository: repository,
            cache: cache,
            session: session,
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        await store.load()
        #expect(store.selectedProject?.code == "A")
        await store.didDeleteProject(code: "A")
        await store.load()
        #expect(store.selectedProject?.code == "B")
    }

    @Test func whitespaceSaveCannotReuseAnEarlierSuccessFlag() async throws {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let model = TestDependencies.detail(
            reference: .init(projectCode: "DEMO", caseID: 2),
            network: APIMockManager(),
            dao: cache,
            session: session
        )
        try await model.fetchCaseDataJSON()
        model.changedTestCase?.title = "Valid title"
        try await model.updateTestCaseData()
        #expect(model.isUploadingSuccess)
        model.changedTestCase?.title = "   "
        do {
            try await model.updateTestCaseData()
            Issue.record("Invalid draft must fail explicitly")
        } catch {
            #expect(!model.isUploadingSuccess)
            #expect(model.hasUnsavedChanges)
        }
    }
}

private final class LifecycleNetwork: NetworkManager {
    var requestedURLs: [URL] = []
    var operations: [API.Operation] = []
    var offline = false
    var responseBody = #"{"status":true}"#
    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        operations.append(operation)
        if let url = API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems) {
            requestedURLs.append(url)
        }
        if offline { throw .noInternetConnection }
        return try API.decodeResponse(from: Data(responseBody.utf8), as: modelType)
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidRequest("No multipart fixture") }
    func auth(by token: String) async throws -> Bool { true }
}
