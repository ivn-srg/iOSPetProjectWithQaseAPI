import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@MainActor
struct HomeViewModelTests {
    @Test("Metrics can refresh while a failed run section retains its cached value")
    func partialRefresh() async {
        let session = SessionContext(ownerID: "partial")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let oldDate = Date(timeIntervalSince1970: 10)
        let currentDate = Date(timeIntervalSince1970: 20)
        let cachedRun = ActiveRunSummary(
            id: 7,
            title: "Saved run",
            startTime: nil,
            progress: nil,
            statusText: nil
        )
        _ = cache.saveHomeSnapshot(
            HomeSnapshot(
                projectCode: "A",
                activeRun: cachedRun,
                metricsUpdatedAt: oldDate,
                runUpdatedAt: oldDate
            ),
            stamp: session.capture()
        )
        let network = HomeStateNetwork { operation, _ in
            if operation == .getRuns { throw API.NetError.otherNetworkError("offline") }
            return Data(
                "{\"status\":true,\"result\":{\"title\":\"Project A\",\"code\":\"A\",\"counts\":{\"cases\":42}}}"
                    .utf8
            )
        }
        let repository = HomeRepository(
            network: network,
            dao: cache,
            session: session,
            clock: { currentDate }
        )
        let selection = SelectedProjectStore(
            repository: repository,
            cache: cache,
            session: session,
            defaults: isolatedDefaults()
        )
        selection.commit(ProjectSummary(title: "Project A", code: "A"))
        let model = HomeViewModel(
            repository: repository,
            cache: cache,
            selection: selection,
            session: session,
            clock: { currentDate }
        )
        await model.reload()
        #expect(model.metrics?.cases == 42)
        #expect(model.metrics?.suites == nil)
        #expect(model.activeRun == cachedRun)
        #expect(model.metricsUpdatedAt == currentDate)
        #expect(model.runUpdatedAt == oldDate)
        #expect(model.metricsError == nil)
        #expect(model.runError != nil)
        #expect(model.showingSavedData)
        #expect(!model.metricsLoading && !model.runLoading)
    }

    @Test("A delayed project A response never replaces the selected project B")
    func projectRace() async {
        let session = SessionContext(ownerID: "race")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let control = HomeResponseControl()
        let network = HomeStateNetwork { operation, code in
            if operation ==
                .getRuns { return Data("{\"status\":true,\"result\":{\"total\":0,\"entities\":[]}}".utf8) }
            return await control.projectResponse(code: code)
        }
        let repository = HomeRepository(network: network, dao: cache, session: session)
        let selection = SelectedProjectStore(
            repository: repository,
            cache: cache,
            session: session,
            defaults: isolatedDefaults()
        )
        selection.commit(ProjectSummary(title: "A", code: "A"))
        let model = HomeViewModel(
            repository: repository,
            cache: cache,
            selection: selection,
            session: session
        )
        let first = Task { await model.reload() }
        await control.waitUntilSuspended()
        selection.commit(ProjectSummary(title: "B", code: "B"))
        await model.reload()
        control.resumeA()
        await first.value
        #expect(model.project?.code == "B")
        #expect(model.metrics?.cases == 2)
        #expect(selection.selectedProject?.code == "B")
        #expect(model.metricsError == nil)
    }

    @Test("Invalidating the session immediately clears visible home state")
    func logoutClearsState() async {
        let session = SessionContext(ownerID: "logout")
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        let repository = HomeRepository(network: APIMockManager(), dao: cache, session: session)
        let selection = SelectedProjectStore(
            repository: repository,
            cache: cache,
            session: session,
            defaults: isolatedDefaults()
        )
        selection.commit(ProjectSummary(title: "Demo", code: "DEMO"))
        let model = HomeViewModel(
            repository: repository,
            cache: cache,
            selection: selection,
            session: session
        )
        await model.reload()
        #expect(model.activeRun != nil)
        session.invalidate()
        #expect(model.project == nil)
        #expect(model.activeRun == nil)
        #expect(model.metrics == nil)
        #expect(model.recentCases.isEmpty)
    }

    private func isolatedDefaults() -> UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }
}

@MainActor
private final class HomeResponseControl {
    private var projectAResponse: CheckedContinuation<Data, Never>?
    private var suspendedWaiter: CheckedContinuation<Void, Never>?
    func projectResponse(code: String) async -> Data {
        if code == "A" {
            return await withCheckedContinuation { continuation in
                projectAResponse = continuation
                suspendedWaiter?.resume()
                suspendedWaiter = nil
            }
        }
        return payload(code: code, count: 2)
    }

    func waitUntilSuspended() async {
        guard projectAResponse == nil else { return }
        await withCheckedContinuation { suspendedWaiter = $0 }
    }

    func resumeA() {
        projectAResponse?.resume(returning: payload(code: "A", count: 1))
        projectAResponse = nil
    }

    private func payload(code: String, count: Int) -> Data {
        Data(
            "{\"status\":true,\"result\":{\"title\":\"\(code)\",\"code\":\"\(code)\",\"counts\":{\"cases\":\(count)}}}"
                .utf8
        )
    }
}

private final class HomeStateNetwork: NetworkManager {
    private let response: @MainActor (API.Operation, String) async throws -> Data
    init(response: @escaping @MainActor (API.Operation, String) async throws -> Data) {
        self.response = response }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        do {
            let data = try await response(operation, pathParameters["code"] ?? "")
            return try API.decodeResponse(from: data, as: modelType)
        } catch let error as API.NetError { throw error }
        catch { throw .otherNetworkError(error.localizedDescription) }
    }

    func performRequest<T: Decodable>(
        with data: Encodable?,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidRequest("Operation required") }
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
    ) -> URL? { nil }
    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? { API.makeURL(
        for: operation,
        pathParameters: pathParameters,
        queryItems: queryItems
    ) }
    func auth(by token: String) async throws -> Bool { true }
}
