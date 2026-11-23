import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
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

    // MARK: - Создание проекта

    /// Ловит: удалена проверка `isEmpty` (или без trim) — запрос уходит с пустым кодом проекта.
    @Test func emptyProjectDraftSendsNothingAndReportsMissingFields() async throws {
        let network = LifecycleNetwork()
        let model = CreatingProjectViewModel(network: network, session: SessionContext(ownerID: "owner"))
        var alerts = 0
        var finished = 0
        model.showErrorClosure = { _, _ in alerts += 1 }
        model.creatingFinishCallback = { finished += 1 }
        model.creatingProject.title = "Title"
        model.creatingProject.code = "   "
        try await model.createNewProject()
        #expect(network.operations.isEmpty)
        #expect(model.isFieldsEmpty && !model.isEntityWasCreated && !model.isSaving)
        #expect(alerts == 1 && finished == 0)
    }

    /// Ловит: baseline не обновляется после успеха; колбэк вызывается дважды; в тело не попал `code`
    /// или `description`.
    @Test func successfulProjectCreationConfirmsDraftAndNotifiesOnce() async throws {
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":true,"result":{"code":"NEW"}}"#
        let model = CreatingProjectViewModel(network: network, session: SessionContext(ownerID: "owner"))
        var finished = 0
        model.creatingFinishCallback = { finished += 1 }
        model.creatingProject.title = "New project"
        model.creatingProject.code = "NEW"
        model.creatingProject.description = "About"
        #expect(model.hasUnsavedChanges)
        try await model.createNewProject()
        #expect(model.isEntityWasCreated && !model.isSaving)
        #expect(finished == 1)
        #expect(!model.hasUnsavedChanges)
        let body = try #require(network.capturedBodies.last)
        let payload = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(Set(payload.keys) == ["title", "code", "description"])
        #expect(payload["title"] as? String == "New project")
        #expect(payload["code"] as? String == "NEW")
        #expect(payload["description"] as? String == "About")
    }

    /// Ловит: удалён guard `status` — отказ сервера считается успехом, черновик «сохранён».
    @Test func projectCreationWithFalseStatusFailsAndKeepsTheDraft() async {
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":false,"result":{"code":"X"}}"#
        let model = CreatingProjectViewModel(network: network, session: SessionContext(ownerID: "owner"))
        var finished = 0
        model.creatingFinishCallback = { finished += 1 }
        model.creatingProject.title = "New project"
        model.creatingProject.code = "X"
        let error = await thrownError { try await model.createNewProject() }
        #expect(invalidRequestMessage(error) == "Create failed")
        #expect(network.operations == [.createProject])
        #expect(!model.isEntityWasCreated && !model.isSaving && finished == 0)
        #expect(model.hasUnsavedChanges)
    }

    /// Ловит: удалён guard `!isSaving` — второе нажатие шлёт повторный POST, пока первый в полёте.
    @Test func secondProjectSaveWhileTheFirstIsInFlightIsRejected() async throws {
        let network = GatedNetwork(responseBody: #"{"status":true,"result":{"code":"NEW"}}"#)
        network.holdNext = 1
        let model = CreatingProjectViewModel(network: network, session: SessionContext(ownerID: "owner"))
        var finished = 0
        model.creatingFinishCallback = { finished += 1 }
        model.creatingProject.title = "New project"
        model.creatingProject.code = "NEW"
        let first = Task { try await model.createNewProject() }
        await waitForCondition { network.isHolding }
        #expect(model.isSaving)
        let second = await thrownError { try await model.createNewProject() }
        #expect(second is CancellationError)
        #expect(network.operations == [.createProject])
        network.release()
        try await first.value
        #expect(finished == 1 && !model.isSaving && !model.hasUnsavedChanges)
    }

    /// Ловит: удалена проверка сессии после ответа — устаревшая форма подтверждает черновик и закрывается.
    @Test func projectResponseAfterSessionChangeDoesNotConfirmDraftOrNotify() async {
        let session = SessionContext(ownerID: "old")
        let network = GatedNetwork(responseBody: #"{"status":true,"result":{"code":"NEW"}}"#)
        network.holdNext = 1
        let model = CreatingProjectViewModel(network: network, session: session)
        var finished = 0
        model.creatingFinishCallback = { finished += 1 }
        model.creatingProject.title = "New project"
        model.creatingProject.code = "NEW"
        let save = Task { try await model.createNewProject() }
        await waitForCondition { network.isHolding }
        session.activate(ownerID: "new")
        network.release()
        let error = await thrownError { try await save.value }
        #expect(error is CancellationError)
        #expect(finished == 0 && !model.isEntityWasCreated && !model.isSaving)
        #expect(model.hasUnsavedChanges)
    }
}

private final class LifecycleNetwork: NetworkManager {
    var requestedURLs: [URL] = []
    var operations: [API.Operation] = []
    var offline = false
    var responseBody = #"{"status":true}"#
    /// Тела запросов в том виде, в каком их отправил бы `APIManager`.
    var capturedBodies: [Data] = []
    /// Значения query `offset` по порядку запросов.
    var requestedOffsets: [Int] = []
    /// Ответ по `offset`; без записи отвечает `responseBody`.
    var responsesByOffset: [Int: String] = [:]
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
        if let data, let encoded = try? API.encodeBody(data) { capturedBodies.append(encoded) }
        let offset = queryItems.first { $0.name == "offset" }.flatMap { Int($0.value ?? "") }
        if let offset { requestedOffsets.append(offset) }
        if offline { throw .noInternetConnection }
        let body = offset.flatMap { responsesByOffset[$0] } ?? responseBody
        return try API.decodeResponse(from: Data(body.utf8), as: modelType)
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidRequest("No multipart fixture") }
    func auth(by token: String) async throws -> Bool { true }
}

/// Фейк с приостановкой: первые `holdNext` запросов ждут `release()`, остальные отвечают сразу.
/// Состояние на MainActor; методы протокола `nonisolated`, чтобы `T.Type` не пересекал границу акторов.
@MainActor
private final class GatedNetwork: NetworkManager {
    var responseBody: String
    var holdNext = 0
    private(set) var operations: [API.Operation] = []
    private var gate: CheckedContinuation<Void, Never>?
    var isHolding: Bool { gate != nil }

    init(responseBody: String) { self.responseBody = responseBody }

    func release() {
        gate?.resume()
        gate = nil
    }

    private func respond(operation: API.Operation) async -> String {
        operations.append(operation)
        if holdNext > 0 {
            holdNext -= 1
            await withCheckedContinuation { gate = $0 }
        }
        return responseBody
    }

    nonisolated func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        let reply = await respond(operation: operation)
        return try API.decodeResponse(from: Data(reply.utf8), as: modelType)
    }

    nonisolated func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }
    nonisolated func auth(by token: String) async throws -> Bool { true }
}

/// Вызывает операцию и возвращает брошенную ошибку; успех даёт `nil`.
@MainActor
private func thrownError(_ operation: () async throws -> Void) async -> Error? {
    do { try await operation() } catch { return error }
    return nil
}

private func invalidRequestMessage(_ error: Error?) -> String? {
    guard case .invalidRequest(let message)? = error as? API.NetError else { return nil }
    return message
}

private func project(_ code: String) -> Project {
    var project = Project()
    project.code = code
    project.title = "Project \(code)"
    return project
}

private func projectsPage(_ codes: [String], total: Int) -> String {
    let entities = codes.map { #"{"title":"Project \#($0)","code":"\#($0)"}"# }.joined(separator: ",")
    return #"{"status":true,"result":{"total":\#(total),"filtered":\#(total),"#
        + #""count":\#(codes.count),"entities":[\#(entities)]}}"#
}

@Suite(.timeLimit(.minutes(1))) @MainActor
struct ProjectsListViewModelTests {
    let session: SessionContext
    let cache: RealmManager

    init() {
        let session = SessionContext(ownerID: "owner")
        self.session = session
        cache = TestDependencies.cache(session: session)
    }

    /// Ловит: удалено чтение кеша при `.start` — до ответа сервера экран пуст.
    @Test func startShowsCachedProjectsBeforeTheResponseArrives() async throws {
        #expect(cache.saveProjects([project("CACHED")], stamp: session.capture()))
        let network = GatedNetwork(responseBody: projectsPage(["NET"], total: 1))
        network.holdNext = 1
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        let load = Task { try await model.requestEntitiesData(place: .start) }
        await waitForCondition { network.isHolding }
        #expect(model.projects.map(\.code) == ["CACHED"])
        #expect(model.isLoading)
        network.release()
        try await load.value
        #expect(model.projects.map(\.code) == ["NET"])
        #expect(!model.isLoading)
    }

    /// Ловит: смещение следующей страницы не растёт (запрос снова с `offset=0`); дописывание без
    /// фильтра дублей по `code`; после достижения `total` уходит лишний запрос.
    @Test func nextPageUsesOffsetFiftyAndAppendsWithoutDuplicates() async throws {
        let firstPage = (0..<50).map { String(format: "P%02d", $0) }
        let network = LifecycleNetwork()
        network.responsesByOffset = [
            0: projectsPage(firstPage, total: 52),
            50: projectsPage(["P49", "P50", "P51"], total: 52)
        ]
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        try await model.requestEntitiesData(place: .start)
        #expect(model.projects.map(\.code) == firstPage)
        try await model.requestEntitiesData(place: .continuos)
        #expect(model.projects.map(\.code) == firstPage + ["P50", "P51"])
        try await model.requestEntitiesData(place: .continuos)
        #expect(network.requestedOffsets == [0, 50])
    }

    /// Ловит: `.refresh` дописывает страницу к списку из кеша вместо замены, либо не сбрасывает offset.
    @Test func refreshReplacesTheListWithTheFirstPage() async throws {
        let network = LifecycleNetwork()
        network.responseBody = projectsPage(["A", "B"], total: 2)
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        try await model.requestEntitiesData(place: .start)
        #expect(model.projects.map(\.code) == ["A", "B"])
        network.responseBody = projectsPage(["C"], total: 1)
        try await model.requestEntitiesData(place: .refresh)
        #expect(model.projects.map(\.code) == ["C"])
        #expect(network.requestedOffsets == [0, 0])
    }

    /// Ловит: удалён guard `!isLoading` — повторный запрос во время загрузки уходит на сервер.
    @Test func requestWhileLoadingDoesNotSendASecondRequest() async throws {
        let network = GatedNetwork(responseBody: projectsPage(["A"], total: 5))
        network.holdNext = 1
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        let load = Task { try await model.requestEntitiesData(place: .start) }
        await waitForCondition { network.isHolding }
        try await model.requestEntitiesData(place: .continuos)
        #expect(network.operations == [.getProjects])
        network.release()
        try await load.value
        #expect(network.operations == [.getProjects])
        #expect(model.projects.map(\.code) == ["A"])
    }

    /// Ловит: удалена проверка `generation` — ответ после `cancelLoading` публикуется;
    /// `cancelLoading` не снимает `isLoading`.
    @Test func responseAfterCancelLoadingIsNotPublished() async throws {
        let network = GatedNetwork(responseBody: projectsPage(["A"], total: 1))
        network.holdNext = 1
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        let load = Task { try await model.requestEntitiesData(place: .start) }
        await waitForCondition { network.isHolding }
        model.cancelLoading()
        #expect(!model.isLoading)
        network.release()
        try await load.value
        #expect(model.projects.isEmpty && !model.isLoading)
        #expect(cache.getProjects()?.count == 0)
    }

    /// Ловит: удалена проверка сессии после ответа — ответ прежнего владельца попадает в список.
    @Test func responseAfterSessionChangeIsNotPublished() async throws {
        let network = GatedNetwork(responseBody: projectsPage(["A"], total: 1))
        network.holdNext = 1
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        let load = Task { try await model.requestEntitiesData(place: .start) }
        await waitForCondition { network.isHolding }
        session.activate(ownerID: "new")
        network.release()
        try await load.value
        #expect(model.projects.isEmpty && !model.isLoading)
    }

    /// Ловит: удалён сброс `isLoading` после ошибки — повторная загрузка блокируется навсегда.
    @Test func failedLoadResetsLoadingAndAllowsRetry() async throws {
        let network = LifecycleNetwork()
        network.offline = true
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        let error = await thrownError { try await model.requestEntitiesData(place: .start) }
        var isOffline = false
        if case .noInternetConnection? = error as? API.NetError { isOffline = true }
        #expect(isOffline)
        #expect(!model.isLoading)
        network.offline = false
        network.responseBody = projectsPage(["A"], total: 1)
        try await model.requestEntitiesData(place: .start)
        #expect(model.projects.map(\.code) == ["A"])
        #expect(network.requestedOffsets == [0, 0])
    }

    /// Ловит: удалён guard `status` — пустой ответ с `status:false` затирает список и кеш.
    @Test func listWithFalseStatusThrowsAndKeepsTheCachedProjects() async {
        #expect(cache.saveProjects([project("CACHED")], stamp: session.capture()))
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":false,"result":{"total":0,"filtered":0,"count":0,"entities":[]}}"#
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        let error = await thrownError { try await model.requestEntitiesData(place: .start) }
        #expect(invalidRequestMessage(error) == "Projects could not be loaded")
        #expect(model.projects.map(\.code) == ["CACHED"])
        #expect(cache.getProjects()?.map(\.code) == ["CACHED"])
        #expect(!model.isLoading)
    }

    /// Ловит: удалён guard `status` при удалении — отказ сервера не даёт ошибки.
    @Test func deleteWithFalseStatusThrowsAndKeepsListAndCache() async {
        #expect(cache.saveProjects([project("A"), project("B")], stamp: session.capture()))
        let network = LifecycleNetwork()
        network.responseBody = #"{"status":false}"#
        let model = ProjectsViewModel(network: network, dao: cache, session: session)
        model.projects = [project("A"), project("B")]
        let error = await thrownError { try await model.deleteProject(project("A")) }
        #expect(invalidRequestMessage(error) == "Project deletion failed")
        #expect(network.operations == [.deleteProject])
        #expect(model.projects.map(\.code) == ["A", "B"])
        #expect(Set(cache.getProjects()?.map(\.code) ?? []) == ["A", "B"])
    }
}
