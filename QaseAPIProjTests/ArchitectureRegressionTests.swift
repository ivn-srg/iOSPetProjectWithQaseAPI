import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing
import UIKit

private struct TransportResponse: Decodable { let status: Bool }

private actor RecordingTransport: HTTPTransport {
    private(set) var requests: [URLRequest] = []
    
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        return (Data("{\"status\":true}".utf8), response)
    }
}

@Suite(.timeLimit(.minutes(1))) @MainActor
struct ArchitectureRegressionTests {
    @Test(.timeLimit(.minutes(1))) func removingEditorReleasesItBeforePendingRequestCompletes() async throws {
        let session = SessionContext(ownerID: "editor")
        let transport = SuspendedEditorTransport()
        defer { Task { await transport.finish() } }
        let network = APIManager(tokenProvider: { "fixture" }, transport: transport)
        let model = TestDependencies.detail(
            reference: .init(projectCode: "A", caseID: 1),
            network: network,
            session: session
        )
        var controller: TestCaseViewController? = TestCaseViewController(
            viewModel: model,
            form: GeneralDetailCaseViewController(vm: model),
            session: session
        )
        weak var releasedController = controller
        controller?.loadViewIfNeeded()
        await transport.waitUntilStarted()
        
        controller?.viewWillDisappear(false)
        controller = nil
        await transport.waitUntilCancelled()
        
        #expect(releasedController == nil)
        #expect(model.testCase == nil && model.changedTestCase == nil)
    }
    
    @Test(.timeLimit(.minutes(1))) func invalidatingSessionCancelsPendingEditorRequest() async throws {
        let session = SessionContext(ownerID: "editor")
        let transport = SuspendedEditorTransport()
        defer { Task { await transport.finish() } }
        let network = APIManager(tokenProvider: { "fixture" }, transport: transport)
        let model = TestDependencies.detail(
            reference: .init(projectCode: "A", caseID: 1),
            network: network,
            session: session
        )
        let controller = TestCaseViewController(
            viewModel: model,
            form: GeneralDetailCaseViewController(vm: model),
            session: session
        )
        controller.loadViewIfNeeded()
        await transport.waitUntilStarted()
        
        session.invalidate()
        await transport.waitUntilCancelled()
        
        #expect(model.testCase == nil && model.changedTestCase == nil)
        #expect(!model.isSessionCurrent)
    }
    
    @Test(.timeLimit(.minutes(1))) func cancelledFetchIgnoresLateSuccessfulResponse() async throws {
        let fixtureURL = try #require(Bundle(for: TestCaseViewController.self).url(
            forResource: "test_cases_data",
            withExtension: "json"
        ))
        let fixture = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL))
                                   as? [String: Any])
        let result = try #require(fixture["result"] as? [String: Any])
        let entities = try #require(result["entities"] as? [[String: Any]])
        let entity = try #require(entities.first)
        let id = try #require(entity["id"] as? Int)
        let body = try JSONSerialization.data(withJSONObject: ["status": true, "result": entity])
        let session = SessionContext(ownerID: "editor")
        let cache = TestDependencies.cache(session: session)
        let transport = SuspendedEditorTransport()
        defer { Task { await transport.finish() } }
        let network = APIManager(tokenProvider: { "fixture" }, transport: transport)
        let reference = TestCaseReference(projectCode: "A", caseID: id)
        let model = TestDependencies.detail(
            reference: reference,
            network: network,
            dao: cache,
            session: session
        )
        let request = Task { try await model.fetchCaseDataJSON() }
        await transport.waitUntilStarted()
        
        request.cancel()
        await transport.waitUntilCancelled()
        await transport.finish(data: body)
        try await request.value
        
        #expect(model.testCase == nil && model.changedTestCase == nil)
        #expect(cache.getTestCase(reference: reference) == nil)
        #expect(cache.getRecentCases(projectCode: "A").isEmpty)
    }
    
    @Test func jsonAndMultipartReadCurrentCredentials() async throws {
        let storage = MemoryCredentialStorage()
        try storage.saveCredential(.init(token: "first", ownerID: "owner"))
        let transport = RecordingTransport()
        let network = APIManager(tokenProvider: { storage.getCredential()?.token }, transport: transport)
        let _: TransportResponse = try await network.performRequest(
            for: .getProjects,
            modelType: TransportResponse.self
        )
        try storage.saveCredential(.init(token: "replacement", ownerID: "owner"))
        let _: TransportResponse = try await network.performRequest(
            for: .getProjects,
            modelType: TransportResponse.self
        )
        let _: TransportResponse = try await network.performMultipartRequest(
            for: .uploadAttachment,
            pathParameters: ["code": "A"],
            files: [.init(
                data: Data([1]),
                fileName: "fixture.txt",
                mimeType: "text/plain"
            )],
            modelType: TransportResponse
                .self
        )
        #expect(try await network.auth(by: "candidate"))
        let headers = await transport.requests.map { $0.value(forHTTPHeaderField: "Token") }
        #expect(headers == ["first", "replacement", "replacement", "candidate"])
        #expect(storage.getCredential()?.token == "replacement")
    }

    /// Qase ждёт `isManual`/`isToBeAutomated` в camelCase рядом с `is_flaky`; остальные тела — snake_case.
    @Test func requestBodyKeepsExplicitKeysAndConvertsOrdinaryKeysToSnakeCase() async throws {
        struct OrdinaryBody: Encodable { let parentId: Int }
        let transport = RecordingTransport()
        let network = APIManager(tokenProvider: { "fixture" }, transport: transport)
        var base = TestCaseEntity.empty
        base.automation = .automation
        var draft = base
        draft.automation = .toBeAutomated
        draft.isFlaky = true
        let _: TransportResponse = try await network.performRequest(
            for: .updateCase,
            pathParameters: ["code": "A", "id": "7"],
            with: TestCaseUpdatePayload(from: base, to: draft),
            modelType: TransportResponse.self
        )
        let _: TransportResponse = try await network.performRequest(
            for: .createSuite,
            pathParameters: ["code": "A"],
            with: OrdinaryBody(parentId: 3),
            modelType: TransportResponse.self
        )
        let bodies = await transport.requests.compactMap { request in
            request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        }
        try #require(bodies.count == 2)
        #expect(Set(bodies[0].keys) == ["isManual", "isToBeAutomated", "is_flaky"])
        #expect(bodies[0]["isManual"] as? Bool == true && bodies[0]["isToBeAutomated"] as? Bool == true)
        #expect(bodies[0]["is_flaky"] as? Int == 1)
        #expect(Set(bodies[1].keys) == ["parent_id"])
        // JSONSerialization не отличает true от 1: тип по схеме Qase проверяется по сырому телу.
        let patch = await transport.requests.first?.httpBody.map { String(decoding: $0, as: UTF8.self) } ?? ""
        #expect(patch.contains(#""isManual":true"#) && patch.contains(#""isToBeAutomated":true"#))
        #expect(patch.contains(#""is_flaky":1"#))
    }
    
    // Ловит: `makeContent` не удаляет токен прежней установки (флаг входа удалён вместе с приложением).
    @Test func reinstalledAppDropsStaleCredentialAndShowsSignIn() throws {
        let domain = "ArchitectureRegressionTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let storage = MemoryCredentialStorage()
        try storage.saveCredential(AuthCredential(token: "real-token", ownerID: "real-owner"))
        let composition = AppCompositionRoot(
            defaults: defaults,
            arguments: [],
            credentialStorage: storage,
            cacheConfiguration: .init(inMemoryIdentifier: UUID().uuidString)
        )
        let root = composition.makeRootController()
        root.loadViewIfNeeded()
        #expect(root.children.first is AuthViewController)
        #expect(storage.getCredential() == nil)
        #expect(composition.session.ownerID == nil)
    }

    // Ловит: `makeContent` не восстанавливает сессию или восстанавливает её после сборки графа —
    // граф захватывает неактивный stamp, проекты не загружаются.
    @Test func coldStartRestoresSessionBeforeBuildingTheShell() async throws {
        let domain = "ArchitectureRegressionTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        defaults.set(true, forKey: "isUserLoggedIn")
        let storage = MemoryCredentialStorage()
        let credential = AuthCredential(token: "QASE_DEMO", ownerID: "demo-owner")
        try storage.saveCredential(credential)
        let composition = AppCompositionRoot(
            defaults: defaults,
            arguments: [],
            credentialStorage: storage,
            cacheConfiguration: .init(inMemoryIdentifier: UUID().uuidString)
        )
        #expect(composition.session.ownerID == nil)
        let root = composition.makeRootController()
        root.loadViewIfNeeded()
        #expect(root.children.first is MainTabbarViewController)
        #expect(composition.session.ownerID == credential.ownerID)
        #expect(storage.getCredential() == credential)
        // Оболочка сразу грузит проекты: с устаревшим stamp `SelectedProjectStore.load()` молча выходит
        // и выбор не записывается.
        await waitForCondition { defaults.string(forKey: "selectedProject.demo-owner") == "DEMO" }
    }

    @Test func authenticatedGraphIsReplacedOnTokenChangeAndReleasedOnLogout() async throws {
        let domain = "ArchitectureRegressionTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let composition = AppCompositionRoot(
            defaults: defaults,
            arguments: ["UITests"],
            credentialStorage: MemoryCredentialStorage(),
            cacheConfiguration: .init(inMemoryIdentifier: UUID().uuidString)
        )
        let root = composition.makeRootController()
        root.loadViewIfNeeded()
        #expect(root.children.first is AuthViewController)
        try await composition.auth.loggedIn(token: "first-demo-token")
        let firstShell = try #require(root.children.first as? MainTabbarViewController)
        let stamp = composition.session.capture()
        let candidate = try await composition.auth.validateReplacementToken("second-demo-token")
        _ = try composition.auth.commitReplacementToken(candidate)
        let replacement = try #require(root.children.first as? MainTabbarViewController)
        #expect(replacement !== firstShell)
        #expect(!composition.session.isCurrent(stamp))
        try await composition.auth.logout()
        #expect(root.children.first is AuthViewController)
        #expect(composition.session.ownerID == nil)
    }
    
    // Мутация: `useDemoStore(true)` оставляет production-конфигурацию (демо видит чужие данные) или
    // `useDemoStore(false)` не возвращает production-хранилище.
    @Test(.timeLimit(.minutes(1)))
    func demoAndProductionStoresDoNotSeeEachOthersData() throws {
        let session = SessionContext(ownerID: "owner")
        let configuration = Realm.Configuration(
            inMemoryIdentifier: UUID().uuidString,
            objectTypes: RealmManager.cacheObjectTypes
        )
        // In-memory Realm живёт, пока открыт хотя бы один экземпляр: без него переключение на демо
        // удалило бы production-данные, и тест проходил бы при любом `useDemoStore`.
        let productionKeeper = try Realm(configuration: configuration)
        defer { withExtendedLifetime(productionKeeper) {} }
        let cache = RealmManager(configuration: configuration, session: session)
        let stamp = session.capture()

        let production = try Self.project("PROD")
        let demo = try Self.project("DEMO")
        #expect(cache.saveProjects([production], stamp: stamp))
        #expect(cache.getProjects()?.map(\.code) == ["PROD"])

        cache.useDemoStore(true)
        #expect(cache.getProjects()?.map(\.code) == [String]())
        #expect(cache.saveProjects([demo], stamp: stamp))
        #expect(cache.getProjects()?.map(\.code) == ["DEMO"])
        try cache.clearAll()
        #expect(cache.getProjects()?.map(\.code) == [String]())

        cache.useDemoStore(false)
        #expect(cache.getProjects()?.map(\.code) == ["PROD"])
    }

    // Мутация: `isDemoMode` не зависит от токена (всегда `true` при наличии credential); composition
    // не переключает кеш на демо-хранилище (`configureDemoMode` без `useDemoStore`) — тогда выход из демо
    // очищает production-кеш; `logout` не удаляет credential или не сбрасывает владельца сессии.
    @Test(.timeLimit(.minutes(1)))
    func demoLoginSwitchesToDemoModeAndLogoutRemovesCredential() async throws {
        let domain = "ArchitectureRegressionTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let storage = MemoryCredentialStorage()
        try storage.saveCredential(AuthCredential(token: "real-token", ownerID: "real-owner"))
        let configuration = Realm.Configuration(
            inMemoryIdentifier: UUID().uuidString,
            objectTypes: RealmManager.cacheObjectTypes
        )
        // Сильная ссылка держит production in-memory Realm, пока composition работает с демо-хранилищем.
        let productionKeeper = try await Realm(configuration: configuration)
        defer { withExtendedLifetime(productionKeeper) {} }
        let composition = AppCompositionRoot(
            defaults: defaults,
            arguments: [],
            credentialStorage: storage,
            cacheConfiguration: configuration
        )
        #expect(!composition.auth.isDemoMode)

        try await composition.auth.loggedIn(token: "QASE_DEMO")
        let credential = try #require(storage.getCredential())
        #expect(credential.token == "QASE_DEMO")
        #expect(credential.ownerID != "real-owner")
        #expect(composition.auth.isDemoMode)
        #expect(composition.auth.isUserLoggedIn())
        #expect(composition.session.ownerID == credential.ownerID)

        // Строка production-кеша, записанная мимо composition: выход из демо очищает только демо-хранилище.
        let production = ProjectRO(projectData: try Self.project("PROD"), ownerID: "real-owner")
        try productionKeeper.write { productionKeeper.add(production) }
        try await composition.auth.logout()
        productionKeeper.refresh()
        #expect(productionKeeper.objects(ProjectRO.self).map(\.code) == ["PROD"])
        #expect(storage.getCredential() == nil)
        #expect(!composition.auth.isDemoMode)
        #expect(!composition.auth.isUserLoggedIn())
        #expect(composition.session.ownerID == nil)
    }

    private static func project(_ code: String) throws -> Project {
        try JSONDecoder().decode(Project.self, from: Data(#"{"title":"\#(code)","code":"\#(code)"}"#.utf8))
    }

    @Test func fixedAndDynamicIdentifiersPreserveLegacyValues() {
        #expect(AccessibilityID.field(.title).identifier == "field.Title")
        #expect(AccessibilityID.breadcrumb(nil).identifier == "repository.breadcrumb.root")
        #expect(AccessibilityID.recent(project: "A", caseID: 42).identifier == "recent.A-42")
        #expect(AccessibilityID.step("12.10.3").identifier == "case.step.12.10.3")
        let fields = AccessibilityID.Field.allCases.map { AccessibilityID.field($0).identifier }
        #expect(Set(fields).count == fields.count)
        #expect(Set(AppTab.allCases.map { $0.accessibilityID.identifier }).count == AppTab.allCases.count)
    }
    
    @Test func unchangedIdentityStillRoundTripsFullStepContentThroughRealm() throws {
        let session = SessionContext(ownerID: "owner")
        let cache = TestDependencies.cache(session: session)
        let child = StepsInTestCase(
            hash: "same-child",
            position: 1,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [42],
            action: "child",
            expectedResult: "child result",
            data: "data",
            steps: []
        )
        let reference = TestCaseReference(projectCode: "A", caseID: 42)
        let fixture = TestEntityRO(testCaseData: .empty, reference: reference, ownerID: "owner")
        fixture.id = 42
        var value = try #require(TestCaseEntity(realmObject: fixture))
        value.title = "Regression"
        value.steps = [StepsInTestCase(
            hash: "same-parent",
            position: 1,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "parent",
            expectedResult: "result",
            data: nil,
            steps: [child]
        )]
        value.severity = .critical
        value.priority = .high
        value.status = .draft
        value.behavior = .negative
        value.type = .integration
        value.layer = .api
        value.automation = .toBeAutomated
        #expect(cache.saveTestCase(value, reference: reference, stamp: session.capture()))
        #expect(cache.getTestCase(reference: reference) == value)
    }
}

private actor SuspendedEditorTransport: HTTPTransport {
    private var request: CheckedContinuation<(Data, URLResponse), Error>?
    private var url: URL?
    private var started = false
    private var cancelled = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var cancellationWaiter: CheckedContinuation<Void, Never>?
    
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        url = request.url
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                self.request = continuation
                started = true
                startWaiter?.resume()
                startWaiter = nil
            }
        } onCancel: {
            Task { await self.recordCancellation() }
        }
    }
    
    func waitUntilStarted() async {
        await withTaskCancellationHandler {
            if !started && !Task.isCancelled {
                await withCheckedContinuation { startWaiter = $0 }
            }
        } onCancel: {
            Task { await self.cancelWaits() }
        }
    }
    
    func waitUntilCancelled() async {
        await withTaskCancellationHandler {
            if !cancelled && !Task.isCancelled {
                await withCheckedContinuation { cancellationWaiter = $0 }
            }
        } onCancel: {
            Task { await self.cancelWaits() }
        }
    }
    
    private func recordCancellation() {
        cancelled = true
        cancellationWaiter?.resume()
        cancellationWaiter = nil
    }
    
    private func cancelWaits() {
        startWaiter?.resume()
        startWaiter = nil
        cancellationWaiter?.resume()
        cancellationWaiter = nil
    }
    
    func finish(data: Data? = nil) {
        let continuation = request
        request = nil
        cancelWaits()
        if let data, let url, let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ) {
            continuation?.resume(returning: (data, response))
        } else {
            continuation?.resume(throwing: URLError(.cancelled))
        }
    }
}

private enum CredentialFixtureError: Error { case write, delete }

private final class FailingCredentialStorage: AuthCredentialStorage {
    private var record: AuthCredential?
    var failsWrite = false
    var failsDelete = false
    
    init(record: AuthCredential) { self.record = record }
    func getCredential() -> AuthCredential? { record }
    func saveCredential(_ record: AuthCredential) throws {
        if failsWrite { throw CredentialFixtureError.write }
        self.record = record
    }
    
    func deleteToken() throws {
        if failsDelete { throw CredentialFixtureError.delete }
        record = nil
    }
}

@Suite @MainActor
struct AuthenticationFailureRegressionTests {
    @Test func credentialFailuresPreserveTheActiveSessionAndCache() async throws {
        let domain = "AuthenticationFailureRegressionTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let session = SessionContext(ownerID: "original-owner")
        let original = AuthCredential(token: "original", ownerID: "original-owner")
        let storage = FailingCredentialStorage(record: original)
        defaults.set(true, forKey: "isUserLoggedIn")
        defaults.set("A", forKey: "selectedProject.original-owner")
        var clears = 0
        var notifications = 0
        let auth = AuthManager(
            userDefaults: defaults,
            credentialStore: storage,
            replacementDependencies: .init(
                session: session,
                authenticate: { _, _ in true },
                clearCache: { clears += 1 },
                configureDemoMode: { _ in },
                notifyAuthChanged: { _ in notifications += 1 }
            )
        )
        let stamp = session.capture()
        storage.failsWrite = true
        do { try await auth.loggedIn(token: "candidate")
            Issue.record("Credential write failure must be returned") }
        catch CredentialFixtureError.write { }
        #expect(session.capture() == stamp)
        #expect(auth.getAuthToken() == original.token)
        storage.failsDelete = true
        do { try await auth.logout()
            Issue.record("Credential deletion failure must be returned") }
        catch CredentialFixtureError.delete { }
        #expect(session.capture() == stamp)
        #expect(defaults.bool(forKey: "isUserLoggedIn"))
        #expect(defaults.string(forKey: "selectedProject.original-owner") == "A")
        #expect(clears == 0 && notifications == 0)
    }
}

@Suite @MainActor
struct SessionScopeRegressionTests {
    @Test func oldPagedModelCannotReadOrRequestAfterAnotherOwnerIsActivated() async {
        let session = SessionContext(ownerID: "first")
        var cacheReads = 0
        var requests = 0
        let model = PagedReadViewModel<ProjectSummary>(session: session, cached: { _ in
            cacheReads += 1
            return []
        }, fetch: { _, _ in
            requests += 1
            return QaseAPIListResult(total: 0, filtered: 0, count: 0, entities: [])
        })
        session.invalidate()
        session.activate(ownerID: "second")
        await model.appear()
        await model.reload()
        model.searchChanged()
        #expect(cacheReads == 0 && requests == 0)
        #expect(model.items.isEmpty)
    }
    
    // Ловит: удалён guard сессии в `retry()` — повтор упавшей страницы уходит запросом от имени
    // другого владельца (догрузка своей проверки сессии не имеет).
    @Test func retryAfterOwnerChangeSendsNoRequest() async {
        let session = SessionContext(ownerID: "first")
        var requests = 0
        let model = PagedReadViewModel<ProjectSummary>(session: session, fetch: { _, offset in
            requests += 1
            if offset > 0 { throw URLError(.notConnectedToInternet) }
            let entities = ["A", "B"].map { ProjectSummary(title: $0, code: $0) }
            return QaseAPIListResult(total: 4, filtered: 4, count: 2, entities: entities)
        })
        await model.reload()
        await model.loadMore()
        #expect(requests == 2 && model.errorMessage != nil)
        session.activate(ownerID: "second")
        await model.retry()
        #expect(requests == 2)
    }

    @Test func unknownTotalsRequireAnEmptyOrShortPageBeforeCompletion() {
        #expect(PaginationPolicy.hasMore(received: 50, offset: 50, total: nil))
        #expect(!PaginationPolicy.hasMore(received: 49, offset: 99, total: nil))
        #expect(!PaginationPolicy.hasMore(received: 0, offset: 100, total: nil))
        #expect(!PaginationPolicy.hasMore(received: 50, offset: 100, total: 100))
    }
}
