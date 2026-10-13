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
        #expect(model.projects.map(\.code) == ["B"])
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
    var offline = false
    func performRequest<T: Decodable>(
        with data: Encodable?,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        if let urlString { requestedURLs.append(urlString) }
        if offline { throw .noInternetConnection }
        return try API.decodeResponse(from: Data("{\"status\":true}".utf8), as: modelType)
    }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        try await performRequest(
            with: data,
            from: API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems),
            method: operation.httpMethod,
            modelType: modelType
        )
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidRequest("No multipart fixture") }
    func composeURL(
        for method: API.Endpoint,
        urlComponents: [String?]?,
        queryItems: [API.QueryParams: Int?]?
    ) -> URL? {
        var components = URLComponents(string: API.BASE_URL + "/" + method.rawValue)
        components?.path += "/" + (urlComponents ?? []).compactMap { $0 }.joined(separator: "/")
        return components?.url
    }

    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? {
        API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems)
    }

    func auth(by token: String) async throws -> Bool { true }
}
