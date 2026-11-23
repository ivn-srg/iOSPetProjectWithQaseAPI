import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

/// Тексты ошибок для пользователя: причина (токен, лимит, сервер, связь) или текст экрана, без серверного текста.
@Suite(.timeLimit(.minutes(1))) @MainActor
struct ErrorMessageTests {
    private static let token = "Check your API token in Settings."
    private static let rateLimit = "Too many requests. Try again in a moment."
    private static let unavailable = "Qase is temporarily unavailable. Try again later."
    private static let offline = "Could not connect. Check your internet connection and try again."

    @Test func knownCausesGetTheirOwnTextAndEverythingElseFallsBack() {
        let fallback = "Screen fallback"
        let cases: [(Error, String)] = [
            (API.NetError.httpError(statusCode: 401, message: "Server text", retryAfter: nil), Self.token),
            (API.NetError.httpError(statusCode: 403, message: "Server text", retryAfter: nil), fallback),
            (API.NetError.httpError(statusCode: 429, message: "Server text", retryAfter: 3), Self.rateLimit),
            (API.NetError.httpError(statusCode: 500, message: "Server text", retryAfter: nil), Self.unavailable),
            (API.NetError.httpError(statusCode: 503, message: "Server text", retryAfter: nil), Self.unavailable),
            (API.NetError.noInternetConnection, Self.offline),
            (API.NetError.timeout, Self.offline),
            (URLError(.notConnectedToInternet), Self.offline),
            (URLError(.timedOut), Self.offline),
            (API.NetError.parsingError("keyNotFound result"), fallback),
            (API.NetError.invalidRequest("Projects could not be loaded"), fallback),
            (API.NetError.otherNetworkError("raw"), fallback),
            (CocoaError(.fileReadUnknown), fallback)
        ]
        for (error, expected) in cases {
            let want = expected == fallback ? fallback : expected.localized
            #expect(API.userMessage(for: error, fallback: fallback) == want, "\(error)")
        }
    }

    @Test func lostConnectionFromTransportBecomesOfflineError() async {
        let network = APIManager(tokenProvider: { "token" }, transport: ThrowingTransport(.networkConnectionLost))
        do {
            let _: QaseAPIResponse<QaseAPIIDResult> = try await network.performRequest(
                for: .getProjects,
                modelType: QaseAPIResponse<QaseAPIIDResult>.self
            )
            Issue.record("A transport failure must throw")
        } catch API.NetError.noInternetConnection {
        } catch {
            Issue.record("Expected noInternetConnection, got \(error)")
        }
    }

    @Test func pagedListShowsTokenHintOn401() async {
        let session = SessionContext(ownerID: "owner")
        let model = PagedReadViewModel<RunReadDTO>(session: session) { _, _ in throw Self.unauthorized }
        await model.reload()
        #expect(model.errorMessage == Self.token.localized)
    }

    @Test func detailShowsTokenHintOn401() async {
        let session = SessionContext(ownerID: "owner")
        let model = ReadDetailViewModel<RunReadDTO>(
            session: session,
            cached: { nil },
            failureMessage: "Could not load run",
            fetch: { throw Self.unauthorized }
        )
        await model.load()
        #expect(model.errorMessage == Self.token.localized)
    }

    @Test func homeSectionsShowTokenHintOn401() async {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let repository = HomeRepository(network: UnauthorizedNetwork(), dao: cache, session: session)
        let selection = SelectedProjectStore(
            repository: repository,
            cache: cache,
            session: session,
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard
        )
        selection.commit(ProjectSummary(title: "A", code: "A"))
        let model = HomeViewModel(repository: repository, cache: cache, selection: selection, session: session)
        let stamp = session.capture()
        await model.reload()
        #expect(model.metricsError == Self.token.localized)
        #expect(model.runError == Self.token.localized)
        // 401 не меняет сессию: прежний stamp действителен.
        #expect(session.isCurrent(stamp))
    }

    @Test func projectLoadShowsTokenHintOn401WithoutTouchingSession() async {
        let session = SessionContext(ownerID: "owner")
        let cache = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let selection = SelectedProjectStore(
            repository: HomeRepository(network: UnauthorizedNetwork(), dao: cache, session: session),
            cache: cache,
            session: session,
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard
        )
        let stamp = session.capture()
        await selection.load()
        #expect(selection.errorMessage == Self.token.localized)
        #expect(session.isCurrent(stamp))
    }

    private static let unauthorized = API.NetError.httpError(statusCode: 401, message: "Unauthorized", retryAfter: nil)
}

private actor ThrowingTransport: HTTPTransport {
    let code: URLError.Code
    init(_ code: URLError.Code) { self.code = code }
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) { throw URLError(code) }
}

/// Сеть, отвечающая 401 на любой запрос, как Qase при отозванном токене.
private final class UnauthorizedNetwork: NetworkManager {
    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        throw .httpError(statusCode: 401, message: "Unauthorized", retryAfter: nil)
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    func auth(by token: String) async throws -> Bool { true }
}
