import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

/// Общее ограниченное ожидание условия: каждая итерация отдаёт управление следующему обороту
/// run loop; не дождались — `#expect` падает, тест не висит.
@MainActor
func waitForCondition(_ condition: () -> Bool) async {
    // Ограниченное ожидание: зависший тест не должен блокировать MainActor для всего прогона.
    for _ in 0..<200 where !condition() && !Task.isCancelled {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
    #expect(condition())
}

/// Фейк списка проектов: готовый ответ, ответ после `release()`, ошибка сети или ошибка после `release()`.
/// `pages` и `pagesTotal` задают страницы по `offset`; без записи для смещения отвечает режим.
@MainActor
final class ProjectsSource: ProjectsReading {
    enum Mode {
        case projects([ProjectSummary])
        case suspended([ProjectSummary])
        case suspendedFailure
        case failure
    }

    var mode: Mode
    var pages: [Int: [ProjectSummary]] = [:]
    var pagesTotal: Int?
    private var gate: CheckedContinuation<Void, Never>?
    private var isReleased = false
    private(set) var requests = 0
    private(set) var offsets: [Int] = []

    init(_ mode: Mode) { self.mode = mode }

    func release() {
        isReleased = true
        gate?.resume()
        gate = nil
    }

    func listProjects(offset: Int) async throws -> QaseAPIListResult<ProjectSummary> {
        requests += 1
        offsets.append(offset)
        switch mode {
        case .failure:
            throw API.NetError.noInternetConnection
        case .projects(let projects):
            return page(pages[offset] ?? projects)
        case .suspended(let projects):
            if !isReleased { await withCheckedContinuation { gate = $0 } }
            return page(pages[offset] ?? projects)
        case .suspendedFailure:
            if !isReleased { await withCheckedContinuation { gate = $0 } }
            throw API.NetError.noInternetConnection
        }
    }

    private func page(_ projects: [ProjectSummary]) -> QaseAPIListResult<ProjectSummary> {
        QaseAPIListResult(
            total: pagesTotal ?? projects.count,
            filtered: nil,
            count: projects.count,
            entities: projects
        )
    }
}

/// Заглушка экрана с черновиком; уход можно приостановить и ответить на него вручную.
@MainActor
final class DraftScreen: UIViewController, FormDepartureParticipant {
    var hasUnsavedChanges = true
    var canSaveDraft = true
    var isSavingDraft = false
    var suspendsDeparture = false
    private(set) var departureRequests = 0
    private(set) var finishEditingCalls = 0
    private var pending: CheckedContinuation<Bool, Never>?

    func finishEditing() { finishEditingCalls += 1 }

    func requestDeparture() async -> Bool {
        departureRequests += 1
        guard suspendsDeparture else { return true }
        return await withCheckedContinuation { pending = $0 }
    }

    func answer(_ value: Bool) {
        pending?.resume(returning: value)
        pending = nil
    }

    func saveDraft() async throws {}
    func discardDraft() { hasUnsavedChanges = false }
}

enum TokenFixtureError: Error { case storage, cleanup }

final class TokenCredentialStorage: AuthCredentialStorage {
    private let lock = NSLock()
    private var record: AuthCredential?
    var failSaving = false
    var failDeleting = false
    var savingError: Error?
    private(set) var savedRecords: [AuthCredential] = []
    private(set) var deleteCount = 0

    init(_ credential: AuthCredential) { record = credential }

    func getCredential() -> AuthCredential? {
        lock.lock()
        defer { lock.unlock() }
        return record
    }

    func saveCredential(_ credential: AuthCredential) throws {
        lock.lock()
        defer { lock.unlock() }
        if let savingError { throw savingError }
        guard !failSaving else { throw TokenFixtureError.storage }
        record = credential
        savedRecords.append(credential)
    }

    func deleteToken() throws {
        lock.lock()
        defer { lock.unlock() }
        if failDeleting { throw TokenFixtureError.storage }
        record = nil
        deleteCount += 1
    }
}

@MainActor
final class TokenReplacementFixture {
    let original: AuthCredential
    let session: SessionContext
    let defaults: UserDefaults
    let storage: TokenCredentialStorage
    let originalStamp: SessionStamp
    var authenticate: (String, Bool) async throws -> Bool = { _, _ in true }
    var requests: [(token: String, demo: Bool)] = []
    var events: [String] = []
    var cachedOldData = true
    var failCacheCleanup = false
    var configuredModes: [Bool] = []
    var notifications: [Bool] = []
    var onClearCache: (() -> Void)?
    var onNotify: (() -> Void)?
    var protectedDataAvailable = true

    /// Домен `defaults` удаляется вместе с фикстурой.
    private let domains: TemporaryDefaults
    var defaultsDomain: String { domains.names[0] }

    lazy var auth = AuthManager(
        userDefaults: defaults,
        credentialStore: storage,
        replacementDependencies: AuthReplacementDependencies(
            session: session,
            authenticate: { [unowned self] token, demo in
                requests.append((token, demo))
                return try await authenticate(token, demo)
            },
            clearCache: { [unowned self] in
                events.append("clear")
                onClearCache?()
                if failCacheCleanup { throw TokenFixtureError.cleanup }
                cachedOldData = false
            },
            configureDemoMode: { [unowned self] demo in
                events.append("configure")
                configuredModes.append(demo)
            },
            notifyAuthChanged: { [unowned self] cleanupFailed in
                events.append("notify")
                notifications.append(cleanupFailed)
                onNotify?()
            }
        ),
        isProtectedDataAvailable: { [unowned self] in protectedDataAvailable }
    )

    init() {
        let original = AuthCredential(token: "old-fixture", ownerID: "old-owner")
        let session = SessionContext(ownerID: "old-owner")
        self.original = original
        self.session = session
        let domains = TemporaryDefaults()
        self.domains = domains
        defaults = domains.make()
        storage = TokenCredentialStorage(original)
        originalStamp = session.capture()
        defaults.set(true, forKey: "isUserLoggedIn")
        defaults.set("OLD", forKey: "selectedProject.old-owner")
        defaults.set("OTHER", forKey: "selectedProject.another-owner")
        defaults.set("dark", forKey: "appearancePreference")
        defaults.set(true, forKey: "featureFlag")
    }

    func expectPreserved(stamp: SessionStamp? = nil) {
        #expect(storage.getCredential() == original)
        #expect(storage.savedRecords.isEmpty)
        #expect(storage.deleteCount == 0)
        #expect(session.capture() == (stamp ?? originalStamp))
        #expect(defaults.bool(forKey: "isUserLoggedIn"))
        #expect(defaults.string(forKey: "selectedProject.old-owner") == "OLD")
        #expect(defaults.string(forKey: "selectedProject.another-owner") == "OTHER")
        #expect(defaults.string(forKey: "appearancePreference") == "dark")
        #expect(defaults.bool(forKey: "featureFlag"))
        #expect(cachedOldData)
        #expect(events.isEmpty)
        #expect(configuredModes.isEmpty)
        #expect(notifications.isEmpty)
    }
}

@MainActor
final class TokenValidationGate {
    private var responseContinuation: CheckedContinuation<Bool, Never>?

    func response() async -> Bool {
        await withCheckedContinuation { continuation in
            responseContinuation = continuation
        }
    }

    /// Ограниченное ожидание: без приостановки тест падает по `waitForCondition`, а не висит.
    func waitUntilSuspended() async {
        await waitForCondition { responseContinuation != nil }
    }

    func resume() {
        responseContinuation?.resume(returning: true)
        responseContinuation = nil
    }
}

/// Общее ядро сетевого фейка тестов: записывает запросы, удерживает их по условию и отвечает замыканием.
/// Без заданного `respond` запрос получает ошибку `.invalidRequest` (тест сам не падает — модель
/// обработает её как обычную ошибку сети); ответ по умолчанию задают фабрики в файлах тестов.
/// Состояние на MainActor; методы протокола `nonisolated`, чтобы `T.Type` не пересекал границу акторов.
@MainActor
final class ScriptedNetwork: NetworkManager {
    struct Request: Sendable {
        let operation: API.Operation
        let method: API.HTTPMethod
        let path: [String: String]
        let query: [URLQueryItem]
        let body: Data?

        /// Смещение страницы из query; `nil`, если параметра нет.
        var offset: Int? { query.first { $0.name == "offset" }?.value.flatMap(Int.init) }
    }

    typealias Responder = (Request) -> Result<Data, API.NetError>

    var respond: Responder = { _ in .failure(.invalidRequest("Unexpected request")) }
    /// Запросы, для которых условие истинно, ждут `releaseNext()`/`releaseAll()`.
    var holds: (Request) -> Bool = { _ in false }
    /// Вызывается после удержания, перед ответом (например, сменить сессию или отменить загрузку).
    var beforeResponse: (() -> Void)?
    private(set) var requests: [Request] = []
    private var held: [CheckedContinuation<Void, Never>] = []

    var operations: [API.Operation] { requests.map(\.operation) }
    var methods: [API.HTTPMethod] { requests.map(\.method) }
    /// Тела запросов в том виде, в каком их отправил бы `APIManager`.
    var capturedBodies: [Data] { requests.compactMap(\.body) }
    var pending: Int { held.count }

    init(respond: Responder? = nil) {
        if let respond { self.respond = respond }
    }

    /// Всегда отвечает этим телом.
    static func body(_ json: String) -> Responder { { _ in .success(Data(json.utf8)) } }
    /// Всегда бросает эту ошибку.
    static func failure(_ error: API.NetError) -> Responder { { _ in .failure(error) } }

    func releaseNext() {
        guard !held.isEmpty else { return }
        held.removeFirst().resume()
    }

    func releaseAll() {
        let continuations = held
        held = []
        continuations.forEach { $0.resume() }
    }

    nonisolated func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        var body: Data?
        if let data { body = try API.encodeBody(data) }
        let request = Request(
            operation: operation,
            method: operation.httpMethod,
            path: pathParameters,
            query: queryItems,
            body: body
        )
        switch await handle(request) {
        case .success(let reply): return try API.decodeResponse(from: reply, as: modelType)
        case .failure(let error): throw error
        }
    }

    /// Запись и решение об удержании — в одном синхронном отрезке MainActor: тест, увидевший `pending`,
    /// видит и запись запроса. После возобновления — `beforeResponse`, затем ответ.
    private func handle(_ request: Request) async -> Result<Data, API.NetError> {
        requests.append(request)
        if holds(request) { await withCheckedContinuation { held.append($0) } }
        beforeResponse?()
        return respond(request)
    }

    nonisolated func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    nonisolated func auth(by token: String) async throws -> Bool { true }
}

/// Вызывает операцию и возвращает брошенную `NetError`; другая ошибка или успех дают `nil`.
@MainActor
func thrownNetError(_ operation: () async throws -> Void) async -> API.NetError? {
    do { try await operation() } catch { return error as? API.NetError }
    return nil
}

func invalidRequestMessage(_ error: API.NetError?) -> String? {
    guard case .invalidRequest(let message)? = error else { return nil }
    return message
}

/// Домены `UserDefaults` теста: удаляются, когда владелец (suite-структура или фикстура) освобождается.
final class TemporaryDefaults {
    private(set) var names: [String] = []

    func make() -> UserDefaults {
        let name = "QaseAPIProjTests." + UUID().uuidString
        names.append(name)
        return UserDefaults(suiteName: name)!
    }

    deinit { names.forEach { UserDefaults.standard.removePersistentDomain(forName: $0) } }
}
