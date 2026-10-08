import Foundation
import Testing
@testable import QaseAPIProj
#if canImport(RealmSwift)
import RealmSwift
#endif

struct HomeDataTests {
    @Test("Project counts preserve missing, null, and zero")
    func optionalProjectMetrics() throws {
        let project = try decode(ProjectSummary.self, """
        {"title":"Demo","code":"DEMO","counts":{"cases":0,"suites":null,"runs":{"total":4},"defects":null}}
        """)
        #expect(project.metrics == ProjectMetrics(cases: 0, suites: nil, runs: 4, defects: nil))
        #expect(try decode(ProjectSummary.self, "{\"title\":\"Empty\",\"code\":\"E\"}").metrics == ProjectMetrics())
        #expect(try JSONDecoder().decode(ProjectSummary.self, from: JSONEncoder().encode(project)) == project)
    }

    @Test("Nested statuses override deprecated counters without adding them")
    func statusesTakePrecedence() throws {
        let stats = try decode(RunStats.self, """
        {"total":32,"statuses":{"untested":8,"in_progress":4,"retest":2,"passed":17,"custom":1},"untested":31,"in_progress":0,"retest":0}
        """)
        #expect(stats.progress == RunProgress(total: 32, completed: 18, percent: 56))
        #expect(stats.statuses?["custom"] == 1)
    }

    @Test("Run progress handles legacy, incomplete, empty, and invalid counters")
    func progressBoundaries() throws {
        #expect(try decode(RunStats.self, "{\"total\":3,\"untested\":1,\"in_progress\":0,\"retest\":0}").progress == RunProgress(total: 3, completed: 2, percent: 67))
        #expect(try decode(RunStats.self, "{\"total\":3,\"untested\":1}").progress == nil)
        #expect(try decode(RunStats.self, "{\"statuses\":{}}").progress == nil)
        #expect(try decode(RunStats.self, "{\"total\":0}").progress == RunProgress(total: 0, completed: 0, percent: 0))
        #expect(try decode(RunStats.self, "{\"total\":3,\"statuses\":{}}").progress == RunProgress(total: 3, completed: 3, percent: 100))
        #expect(try decode(RunStats.self, "{\"total\":3,\"statuses\":{\"untested\":9}}").progress?.completed == 0)
        #expect(try decode(RunStats.self, "{\"total\":3,\"statuses\":{\"untested\":-1}}").progress?.completed == 3)
    }

    @Test("Run DTO supports nullable and fractional ISO dates and cache round-trip")
    func runDatesAndCases() throws {
        let run = try decode(RunReadDTO.self, """
        {"id":7,"title":"Smoke","status":0,"status_text":"in_progress","start_time":"2026-10-03T12:34:56.123Z","cases":[2,3]}
        """)
        #expect(run.startTime != nil)
        #expect(run.cases == [2, 3])
        #expect(try decode(RunReadDTO.self, "{\"id\":1,\"title\":\"No date\",\"start_time\":null}").startTime == nil)
        let restored = try JSONDecoder().decode(RunReadDTO.self, from: JSONEncoder().encode(run))
        #expect(restored == run)
    }

    @Test("References isolate repeated case identifiers across projects")
    func referenceIdentity() {
        #expect(TestCaseReference(projectCode: "A", caseID: 1).cacheKey != TestCaseReference(projectCode: "B", caseID: 1).cacheKey)
        #expect(TestCaseReference(projectCode: "A", caseID: 1).cacheKey == TestCaseReference(projectCode: "A", caseID: 1).cacheKey)
    }

    @Test("Unknown defect strings are preserved")
    func unknownDefectStatus() throws {
        let defect = try decode(DefectReadDTO.self, "{\"id\":5,\"title\":\"Bug\",\"severity\":\"custom_severity\",\"status\":\"triage\",\"actual_result\":\"Observed\"}")
        #expect(defect.severity == "custom_severity")
        #expect(defect.status == "triage")
        #expect(defect.actualResult == "Observed")
    }

    @Test("Mock respects detail routes, include, search, project and pagination")
    @MainActor func mockRoutes() async throws {
        let repository = HomeRepository(network: APIMockManager.shared, session: SessionContext(ownerID: "mock-test"))
        #expect(try await repository.project(code: "DEMO").code == "DEMO")
        #expect(try await repository.project(code: "1F").code == "1F")
        let cases = try await repository.cases(projectCode: "1F", query: "Первый запуск", offset: 0)
        #expect(cases.entities.count == 1)
        #expect(cases.entities.first?.id == 2)
        #expect(try await repository.cases(projectCode: "1F", query: "", offset: 50).entities.isEmpty)
        let run = try await repository.run(projectCode: "DEMO", id: 7)
        #expect(run.cases == [2, 3])
        #expect(try await repository.activeRun(projectCode: "DEMO")?.progress == RunProgress(total: 32, completed: 18, percent: 56))
        #expect(try await repository.activeRun(projectCode: "1F") == nil)
        #expect(try await repository.defect(projectCode: "DEMO", id: 1).id == 1)
    }

    @Test("Repository follows every active-run page and deterministically sorts dates and IDs")
    @MainActor func activeRunPagination() async throws {
        let network = HomeRecordingNetwork()
        network.responses = [
            Data("{\"status\":true,\"result\":{\"total\":4,\"count\":2,\"entities\":[{\"id\":99,\"title\":\"Undated\"},{\"id\":1,\"title\":\"Old\",\"start_time\":\"2026-10-01T00:00:00Z\"}]}}".utf8),
            Data("{\"status\":true,\"result\":{\"total\":4,\"count\":2,\"entities\":[{\"id\":2,\"title\":\"Latest\",\"start_time\":\"2026-10-02T00:00:00Z\"},{\"id\":3,\"title\":\"Same time higher ID\",\"start_time\":\"2026-10-02T00:00:00Z\"}]}}".utf8)
        ]
        let repository = HomeRepository(network: network, session: SessionContext(ownerID: "test"))
        #expect(try await repository.activeRun(projectCode: "A")?.id == 3)
        #expect(network.operations == [.getRuns, .getRuns])
        #expect(network.parameters.allSatisfy { $0["code"] == "A" })
        #expect(network.queries[0].contains(URLQueryItem(name: "status", value: "in_progress")))
        #expect(network.queries[1].contains(URLQueryItem(name: "offset", value: "2")))
    }

    @Test("Mock creation, update and deletion use exact methods and preserve detail shape")
    func mockMutations() async throws {
        let network = APIMockManager()
        let created = try await network.performRequest(for: .createCase, pathParameters: ["code": "DEMO"], with: QaseAPIObjectRequest(values: ["title": .string("Created case")]), modelType: QaseAPIResponse<QaseAPIIDResult>.self)
        let id = try #require(created.result?.id)
        let detail = try await network.performRequest(for: .getCase, pathParameters: ["code": "DEMO", "id": String(id)], modelType: QaseAPIResponse<CaseSummary>.self)
        #expect(detail.result?.title == "Created case")
        let updated = try await network.performRequest(for: .updateCase, pathParameters: ["code": "DEMO", "id": String(id)], with: QaseAPIObjectRequest(values: ["title": .string("Updated case")]), modelType: QaseAPIResponse<QaseAPIIDResult>.self)
        #expect(updated.result?.id == id)
        let newDetail = try await network.performRequest(for: .getCase, pathParameters: ["code": "DEMO", "id": String(id)], modelType: QaseAPIResponse<CaseSummary>.self)
        #expect(newDetail.result?.title == "Updated case")
        _ = try await network.performRequest(for: .deleteCase, pathParameters: ["code": "DEMO", "id": String(id)], modelType: QaseAPIResponse<QaseAPIEmptyResult>.self)
        do {
            _ = try await network.performRequest(for: .getCase, pathParameters: ["code": "DEMO", "id": String(id)], modelType: QaseAPIResponse<CaseSummary>.self)
            Issue.record("Deleted case was returned")
        } catch API.NetError.httpError(let status, _, _) {
            #expect(status == 404)
        }
    }

    @Test("Repository rejects a response from an invalidated session")
    @MainActor func staleSessionResponse() async throws {
        let session = SessionContext(ownerID: "before")
        let network = HomeRecordingNetwork()
        network.responses = [Data("{\"status\":true,\"result\":{\"title\":\"Old\",\"code\":\"A\"}}".utf8)]
        network.onRequest = { session.invalidate() }
        let repository = HomeRepository(network: network, session: session)
        do {
            _ = try await repository.project(code: "A")
            Issue.record("A response from a former session was accepted")
        } catch is CancellationError {}
    }

#if canImport(RealmSwift)
    @Test("Read caches round-trip lists and details with owner and project isolation")
    @MainActor func readCacheRoundTrip() async throws {
        let session = SessionContext(ownerID: "read-cache")
        let configuration = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        let cache = RealmManager(configuration: configuration, session: session)
        let repository = HomeRepository(network: APIMockManager(), dao: cache, session: session)
        _ = try await repository.runs(projectCode: "DEMO")
        _ = try await repository.run(projectCode: "DEMO", id: 7)
        _ = try await repository.defects(projectCode: "DEMO")
        _ = try await repository.defect(projectCode: "DEMO", id: 1)
        _ = try await repository.defect(projectCode: "1F", id: 1)
        _ = try await repository.cases(projectCode: "1F", query: "Первый запуск")
        let restoredCache = RealmManager(configuration: configuration, session: session)
        let restored = HomeRepository(network: APIMockManager(), dao: restoredCache, session: session)
        #expect(restored.cachedRuns(projectCode: "DEMO").count == 2)
        #expect(restored.cachedRun(projectCode: "DEMO", id: 7)?.cases == [2, 3])
        #expect(restored.cachedDefects(projectCode: "DEMO").count == 2)
        #expect(restored.cachedDefect(projectCode: "DEMO", id: 1)?.severity == "major")
        #expect(restored.cachedDefect(projectCode: "1F", id: 1)?.severity == "critical")
        #expect(restored.cachedCases(projectCode: "1F").first?.id == 2)
        #expect(!restored.hasCachedRuns(projectCode: "1F"))
        _ = try await repository.runs(projectCode: "1F")
        #expect(restored.hasCachedRuns(projectCode: "1F"))
        #expect(restored.cachedRuns(projectCode: "1F").isEmpty)
        session.activate(ownerID: "other-owner")
        #expect(restored.cachedRuns(projectCode: "DEMO").isEmpty)
        #expect(restored.cachedRun(projectCode: "DEMO", id: 7) == nil)
        #expect(restored.cachedDefect(projectCode: "DEMO", id: 1) == nil)
    }

    @Test("Complete project pagination prunes deleted projects only after the final page")
    @MainActor func projectCachePruning() async throws {
        let session = SessionContext(ownerID: "project-pages")
        let cache = RealmManager(configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString), session: session)
        _ = cache.saveProjectSummaries([ProjectSummary(title: "Deleted", code: "Z")], stamp: session.capture())
        let network = HomeRecordingNetwork()
        network.responses = [
            Data("{\"status\":true,\"result\":{\"total\":2,\"entities\":[{\"title\":\"A\",\"code\":\"A\"}]}}".utf8),
            Data("{\"status\":true,\"result\":{\"total\":2,\"entities\":[{\"title\":\"B\",\"code\":\"B\"}]}}".utf8)
        ]
        let repository = HomeRepository(network: network, dao: cache, session: session)
        _ = try await repository.listProjects()
        #expect(cache.getProjectSummaries().contains { $0.code == "Z" })
        _ = try await repository.listProjects(offset: 1)
        #expect(Set(cache.getProjectSummaries().map(\.code)) == Set(["A", "B"]))
    }

    @Test("Late run responses never write into a replacement owner's cache")
    @MainActor func staleReadCacheWrite() async throws {
        let session = SessionContext(ownerID: "original-owner")
        let cache = RealmManager(configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = HomeRecordingNetwork()
        network.responses = [Data("{\"status\":true,\"result\":{\"total\":1,\"entities\":[{\"id\":1,\"title\":\"Old run\"}]}}".utf8)]
        network.onRequest = { session.activate(ownerID: "replacement-owner") }
        let repository = HomeRepository(network: network, dao: cache, session: session)
        do {
            _ = try await repository.runs(projectCode: "DEMO")
            Issue.record("A stale run list was accepted")
        } catch is CancellationError {}
        #expect(!repository.hasCachedRuns(projectCode: "DEMO"))
    }
#endif

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }
}

private final class HomeRecordingNetwork: NetworkManager {
    var responses: [Data] = []
    var operations: [API.Operation] = []
    var parameters: [[String: String]] = []
    var queries: [[URLQueryItem]] = []
    var onRequest: (() -> Void)?

    func performRequest<T: Decodable>(for operation: API.Operation, pathParameters: [String: String], queryItems: [URLQueryItem], with data: Encodable?, modelType: T.Type) async throws(API.NetError) -> T {
        operations.append(operation)
        parameters.append(pathParameters)
        queries.append(queryItems)
        onRequest?()
        guard !responses.isEmpty else { throw .invalidRequest("No fixture response") }
        return try API.decodeResponse(from: responses.removeFirst(), as: modelType)
    }

    func performRequest<T: Decodable>(with data: Encodable?, from urlString: URL?, method: API.HTTPMethod, modelType: T.Type) async throws(API.NetError) -> T {
        throw .invalidRequest("Use the operation API")
    }

    func performMultipartRequest<T: Decodable>(for operation: API.Operation, pathParameters: [String: String], files: [API.UploadFile], modelType: T.Type) async throws(API.NetError) -> T {
        throw .invalidRequest("No multipart fixture")
    }

    func composeURL(for method: API.Endpoint, urlComponents: [String?]?, queryItems: [API.QueryParams: Int?]?) -> URL? { nil }
    func composeURL(for operation: API.Operation, pathParameters: [String: String], queryItems: [URLQueryItem]) -> URL? {
        API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems)
    }
    func auth(by token: String) async throws -> Bool { true }
}
