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

    // Мутация: убрать код из `API.offlineCodes` или ветку `.timedOut` в `makeHTTPRequest`.
    @Test(arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
        .dnsLookupFailed, .dataNotAllowed
    ])
    func offlineTransportFailuresBecomeNoInternetConnection(code: URLError.Code) async {
        let error = await Self.failure(of: ThrowingTransport(code))
        guard case API.NetError.noInternetConnection? = error else {
            Issue.record("Expected noInternetConnection for \(code), got \(String(describing: error))")
            return
        }
    }

    // Мутация: вернуть `.timedOut` в общую ветку `otherNetworkError` или смешать с `offlineCodes`.
    @Test func timedOutTransportFailureBecomesTimeout() async {
        let error = await Self.failure(of: ThrowingTransport(.timedOut))
        guard case API.NetError.timeout? = error else {
            Issue.record("Expected timeout, got \(String(describing: error))")
            return
        }
    }

    // Фиксация текущего поведения (NG-3): отмену `APIManager` отдельно не различает.
    // Мутация: добавить `.cancelled` в `offlineCodes` или бросать `CancellationError`.
    @Test func cancelledTransportFailureIsReportedAsOtherNetworkError() async {
        let error = await Self.failure(of: ThrowingTransport(.cancelled))
        guard case API.NetError.otherNetworkError? = error else {
            Issue.record("Expected otherNetworkError, got \(String(describing: error))")
            return
        }
    }

    // Мутация: убрать завершающий `catch` в `makeHTTPRequest` (чужая ошибка уходит наружу как есть).
    @Test func unknownTransportFailureBecomesOtherNetworkError() async {
        let error = await Self.failure(of: StubTransport { throw CocoaError(.fileReadUnknown) })
        guard case API.NetError.otherNetworkError? = error else {
            Issue.record("Expected otherNetworkError, got \(String(describing: error))")
            return
        }
    }

    // Мутация: принять не-HTTP ответ за успех (декодирование пустого тела дало бы `parsingError`).
    @Test func nonHTTPResponseBecomesOtherNetworkError() async {
        let error = await Self.failure(of: StubTransport {
            let url = try #require(URL(string: "https://api.qase.io/v1/project"))
            let response = URLResponse(
                url: url,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (Data(), response)
        })
        guard case API.NetError.otherNetworkError? = error else {
            Issue.record("Expected otherNetworkError, got \(String(describing: error))")
            return
        }
    }

    // Мутация: в `decodeResponse` отдавать ошибку разбора как `otherNetworkError` вместо `parsingError`.
    @Test func malformedSuccessBodyBecomesParsingError() async {
        let error = await Self.failure(of: StubTransport { try Self.httpReply(status: 200, body: "{}") })
        guard case API.NetError.parsingError? = error else {
            Issue.record("Expected parsingError, got \(String(describing: error))")
            return
        }
    }

    // Мутация: проверять статус после декодирования — тело ошибки Qase не разбирается как `QaseAPIIDResult`.
    @Test func serverFailureKeepsStatusAndRetryAfterFromResponse() async {
        let error = await Self.failure(of: StubTransport {
            try Self.httpReply(
                status: 429,
                body: #"{"errorMessage":"slow down"}"#,
                headers: ["Retry-After": "7"]
            )
        })
        guard case API.NetError.httpError(let status, let message, let retryAfter)? = error else {
            Issue.record("Expected httpError, got \(String(describing: error))")
            return
        }
        #expect(status == 429)
        #expect(message == "slow down")
        #expect(retryAfter == 7)
    }

    @Test func validSuccessBodyIsDecoded() async throws {
        let network = APIManager(
            tokenProvider: { "token" },
            transport: StubTransport { try Self.httpReply(status: 200, body: #"{"id":7}"#) }
        )
        let result: QaseAPIIDResult = try await network.performRequest(
            for: .getProjects,
            modelType: QaseAPIIDResult.self
        )
        #expect(result.id == 7)
    }

    private nonisolated static func failure(of transport: some HTTPTransport) async -> (any Error)? {
        let network = APIManager(tokenProvider: { "token" }, transport: transport)
        do {
            let _: QaseAPIIDResult = try await network.performRequest(
                for: .getProjects,
                modelType: QaseAPIIDResult.self
            )
            return nil
        } catch {
            return error
        }
    }

    private nonisolated static func httpReply(
        status: Int,
        body: String,
        headers: [String: String]? = nil
    ) throws -> (Data, URLResponse) {
        let url = try #require(URL(string: "https://api.qase.io/v1/project"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: nil,
            headerFields: headers
        ))
        return (Data(body.utf8), response)
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

/// Транспорт с заданным ответом: тест описывает ответ или сбой замыканием.
private struct StubTransport: HTTPTransport {
    let reply: @Sendable () throws -> (Data, URLResponse)
    init(_ reply: @escaping @Sendable () throws -> (Data, URLResponse)) { self.reply = reply }
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) { try reply() }
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
