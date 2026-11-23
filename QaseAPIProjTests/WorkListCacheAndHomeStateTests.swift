import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

/// Кеш Runs/Defects — последний просмотренный префикс списка (план C1, DC-3/DC-4).
@Suite(.timeLimit(.minutes(1))) @MainActor
struct WorkListPrefixCacheTests {
    @Test func firstPageReplacesStaleRunsAndKeepsServerOrder() async throws {
        let fixture = WorkFixture()
        #expect(fixture.dao.saveRuns(
            [WorkFixture.run(1), WorkFixture.run(2), WorkFixture.run(3)],
            projectCode: "A",
            stamp: fixture.session.capture()
        ))
        fixture.network.replies = [.page([4, 1]), .page([1, 2])]
        _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
        #expect(fixture.dao.getRuns(projectCode: "A")?.map(\.id) == [4, 1])
        _ = try await fixture.repository.runs(projectCode: "A", offset: 2)
        // Запись, сдвинутая на следующую страницу, занимает позицию по последнему ответу.
        #expect(fixture.dao.getRuns(projectCode: "A")?.map(\.id) == [4, 1, 2])
    }

    @Test func lateLoadMoreAfterRefreshDoesNotLeakIntoCache() async throws {
        let fixture = WorkFixture()
        fixture.network.replies = [.page([1, 2]), .page([3]), .page([9, 1])]
        fixture.network.suspendedCalls = [2]
        _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
        let loadMore = Task { try await fixture.repository.runs(projectCode: "A", offset: 2) }
        await waitForCondition { fixture.network.pending != nil }
        _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
        fixture.network.resumePending()
        _ = try await loadMore.value
        #expect(fixture.dao.getRuns(projectCode: "A")?.map(\.id) == [9, 1])
    }

    @Test func continuationWithoutCachedPrefixIsNotWritten() async throws {
        let fixture = WorkFixture()
        fixture.network.replies = [.page([1]), .page([2])]
        _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
        try fixture.dao.clearAll()
        _ = try await fixture.repository.runs(projectCode: "A", offset: 1)
        #expect(fixture.dao.getRuns(projectCode: "A") == nil)
    }

    @Test func defectsFollowTheSamePrefixRule() async throws {
        let fixture = WorkFixture()
        #expect(fixture.dao.saveDefects(
            [WorkFixture.defect(1), WorkFixture.defect(2)],
            projectCode: "A",
            stamp: fixture.session.capture()
        ))
        fixture.network.replies = [.page([3, 1]), .page([2])]
        _ = try await fixture.repository.defects(projectCode: "A", offset: 0)
        #expect(fixture.dao.getDefects(projectCode: "A")?.map(\.id) == [3, 1])
        _ = try await fixture.repository.defects(projectCode: "A", offset: 2)
        #expect(fixture.dao.getDefects(projectCode: "A")?.map(\.id) == [3, 1, 2])
    }

    @Test func activeRunDoesNotCreateRunListCache() async throws {
        let fixture = WorkFixture()
        fixture.network.replies = [.page([5])]
        let active = try await fixture.repository.activeRun(projectCode: "A")
        #expect(active?.id == 5)
        #expect(fixture.dao.getRuns(projectCode: "A") == nil)
        #expect(fixture.dao.getRun(projectCode: "A", id: 5)?.id == 5)
    }

    @Test func activeRunKeepsDetailThatAlreadyHasCases() async throws {
        let fixture = WorkFixture()
        #expect(fixture.dao.saveRun(
            WorkFixture.run(5, title: "Detail", cases: [10, 11]),
            projectCode: "A",
            stamp: fixture.session.capture()
        ))
        fixture.network.replies = [.page([5])]
        _ = try await fixture.repository.activeRun(projectCode: "A")
        let detail = fixture.dao.getRun(projectCode: "A", id: 5)
        #expect(detail?.title == "Detail" && detail?.cases == [10, 11])
    }

    @Test func activeRunRefreshesDetailItWroteItself() async throws {
        let fixture = WorkFixture()
        #expect(fixture.dao.saveRun(
            WorkFixture.run(5, title: "Old progress"),
            projectCode: "A",
            stamp: fixture.session.capture()
        ))
        fixture.network.replies = [.page([5])]
        _ = try await fixture.repository.activeRun(projectCode: "A")
        #expect(fixture.dao.getRun(projectCode: "A", id: 5)?.title == "Run 5")
    }

    @Test func lateRunsPageAfterSessionChangeIsNotCached() async throws {
        let fixture = WorkFixture()
        fixture.network.replies = [.page([1])]
        fixture.network.suspendedCalls = [1]
        let load = Task { try await fixture.repository.runs(projectCode: "A", offset: 0) }
        await waitForCondition { fixture.network.pending != nil }
        fixture.session.activate(ownerID: "other")
        fixture.network.resumePending()
        _ = try? await load.value
        fixture.session.activate(ownerID: "owner")
        #expect(fixture.dao.getRuns(projectCode: "A") == nil)
    }
}

/// Home без выбранного проекта различает загрузку, ошибку с повтором и отсутствие проектов (DC-5).
@Suite(.timeLimit(.minutes(1))) @MainActor
struct HomeNoProjectStateTests {
    @Test func loadingStateLastsUntilProjectsArrive() async {
        let fixture = HomeFixture(.suspended([]))
        let load = Task { await fixture.selection.load() }
        await waitForCondition { fixture.source.requests == 1 }
        #expect(fixture.model.noProjectState == .loading)
        fixture.source.release()
        await load.value
        #expect(fixture.model.noProjectState == .empty)
    }

    @Test func failureOffersRetryThatSelectsProject() async {
        let fixture = HomeFixture(.failure)
        await fixture.selection.load()
        // Фикстура `.failure` бросает `noInternetConnection` — Home называет причину ошибки.
        let offline = "Could not connect. Check your internet connection and try again.".localized
        #expect(fixture.model.noProjectState == .failed(offline))
        fixture.source.mode = .projects([ProjectSummary(title: "A", code: "A")])
        await fixture.model.reloadProjects().value
        #expect(fixture.source.requests == 2)
        #expect(fixture.model.project?.code == "A")
        #expect(fixture.model.noProjectState == .empty)
    }

    /// Сохранённого проекта нет в кеше: выбор ждёт сеть, Home показывает загрузку, а не «нет проектов».
    @Test func loadingWithCachedProjectsButNoSelectionShowsLoading() async {
        let fixture = HomeFixture(
            .suspended([ProjectSummary(title: "A", code: "A")]),
            cached: [ProjectSummary(title: "B", code: "B")],
            savedCode: "A"
        )
        let load = Task { await fixture.selection.load() }
        await waitForCondition { fixture.source.requests == 1 }
        #expect(fixture.model.project == nil)
        #expect(fixture.model.noProjectState == .loading)
        fixture.source.release()
        await load.value
        #expect(fixture.model.project?.code == "A")
    }

    @Test func emptyAccountShowsNoProjectState() async {
        let fixture = HomeFixture(.projects([]))
        await fixture.selection.load()
        #expect(fixture.model.project == nil)
        #expect(fixture.model.noProjectState == .empty)
    }

    @Test func pullToRefreshWithoutProjectReloadsProjects() async {
        let fixture = HomeFixture(.failure)
        await fixture.selection.load()
        fixture.source.mode = .projects([ProjectSummary(title: "A", code: "A")])
        await fixture.model.reload()
        #expect(fixture.source.requests == 2)
        #expect(fixture.model.project?.code == "A")
    }

    @Test func cancellingScreenRefreshDoesNotAbortProjectLoad() async {
        let fixture = HomeFixture(.suspended([ProjectSummary(title: "A", code: "A")]))
        fixture.model.refresh()
        await waitForCondition { fixture.source.requests == 1 }
        // Возврат в foreground отменяет задачу экрана; загрузка store должна продолжиться.
        fixture.model.refresh()
        #expect(fixture.model.noProjectState == .loading)
        fixture.source.release()
        await waitForCondition { fixture.model.project != nil }
        #expect(fixture.model.project?.code == "A")
        #expect(fixture.source.requests == 1)
    }
}

// MARK: - Фикстуры

@MainActor
private final class WorkFixture {
    let session = SessionContext(ownerID: "owner")
    let network = WorkNetwork()
    let dao: RealmManager
    let repository: HomeRepository

    init() {
        dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        repository = HomeRepository(network: network, dao: dao, session: session)
    }

    static func run(_ id: Int, title: String? = nil, cases: [Int]? = nil) -> RunReadDTO {
        let casesJSON = cases.map { ", \"cases\": \($0)" } ?? ""
        let json = #"{"id": \#(id), "title": "\#(title ?? "Run \(id)")"\#(casesJSON)}"#
        // Литерал фикстуры; ошибка декодирования должна уронить тест сразу.
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(RunReadDTO.self, from: Data(json.utf8))
    }

    static func defect(_ id: Int) -> DefectReadDTO {
        let json = #"{"id": \#(id), "title": "Defect \#(id)"}"#
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(DefectReadDTO.self, from: Data(json.utf8))
    }
}

/// N-й запрос получает `replies[N-1]` — страницу с указанными id (`Run N` / `Defect N`);
/// выбранные запросы ждут `resumePending()`. Состояние на MainActor; методы протокола
/// `nonisolated`, чтобы `T.Type` не пересекал границу акторов.
@MainActor
private final class WorkNetwork: NetworkManager {
    enum Reply { case page([Int]) }

    var replies: [Reply] = []
    var suspendedCalls: Set<Int> = []
    private(set) var pending: CheckedContinuation<Void, Never>?
    private var calls = 0

    func resumePending() {
        let continuation = pending
        pending = nil
        continuation?.resume()
    }

    /// Регистрирует вызов, при необходимости ждёт `resumePending()` и отдаёт id страницы.
    private func nextPage() async throws(API.NetError) -> [Int] {
        calls += 1
        let call = calls
        if suspendedCalls.contains(call) { await withCheckedContinuation { pending = $0 } }
        guard call <= replies.count, case .page(let ids) = replies[call - 1]
        else { throw .invalidRequest("Unexpected request #\(call)") }
        return ids
    }

    nonisolated func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        let ids = try await nextPage()
        let prefix = operation == .getDefects ? "Defect" : "Run"
        let entities = ids.map { #"{"id": \#($0), "title": "\#(prefix) \#($0)"}"# }.joined(separator: ",")
        let result = #"{"total": \#(ids.count), "count": \#(ids.count), "entities": [\#(entities)]}"#
        let body = #"{"status": true, "result": \#(result)}"#
        return try API.decodeResponse(from: Data(body.utf8), as: modelType)
    }

    nonisolated func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    nonisolated func auth(by token: String) async throws -> Bool { true }
}

@MainActor
private final class HomeFixture {
    let session = SessionContext(ownerID: "owner")
    let source: ProjectsSource
    let selection: SelectedProjectStore
    let model: HomeViewModel

    /// `cached` — проекты в кеше до загрузки, `savedCode` — сохранённый выбор владельца.
    init(_ mode: ProjectsSource.Mode, cached: [ProjectSummary] = [], savedCode: String? = nil) {
        source = ProjectsSource(mode)
        let cache = RealmManager(
            configuration: .init(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
        #expect(cached.isEmpty || cache.saveProjectSummaries(cached, stamp: session.capture()))
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        if let savedCode { defaults.set(savedCode, forKey: "selectedProject.owner") }
        selection = SelectedProjectStore(
            repository: source,
            cache: cache,
            session: session,
            defaults: defaults
        )
        // Сеть Home не нужна: проект в этих тестах не выбран, а выбранный проект грузится из демо-мока.
        model = HomeViewModel(
            repository: HomeRepository(network: APIMockManager(), dao: cache, session: session),
            cache: cache,
            selection: selection,
            session: session
        )
    }
}
