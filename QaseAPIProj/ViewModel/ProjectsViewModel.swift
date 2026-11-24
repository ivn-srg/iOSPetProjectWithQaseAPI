import Foundation

@MainActor
final class ProjectsViewModel {
    weak var delegate: UpdateTableViewProtocol?
    var projects: [Project] = [] { didSet { delegate?.updateTableView() } }
    var isLoading = false { didSet { delegate?.updateTableView() } }
    private var hasMoreProjects = true
    private var offset = 0
    private var loadGeneration = 0
    private let onCacheFailure: () -> Void
    private let network: NetworkManager
    private let dao: ProjectsCaching
    private let session: SessionContext
    private let stamp: SessionStamp
    /// Проекты, удаление которых уже отправлено: повторное удаление не шлёт второй DELETE.
    private var deletingCodes: Set<String> = []

    enum DeletionOutcome: Equatable { case deleted, alreadyInFlight, cancelled }

    private func reportCacheWrite(_ accepted: Bool) {
        if !accepted { onCacheFailure() }
    }

    init(
        network: NetworkManager,
        dao: ProjectsCaching,
        session: SessionContext,
        onCacheFailure: @escaping () -> Void = {}
    ) {
        self.onCacheFailure = onCacheFailure
        self.network = network
        self.dao = dao
        self.session = session
        self.stamp = session.capture()
    }

    func cancelLoading() {
        loadGeneration += 1
        if isLoading { isLoading = false }
    }

    func requestEntitiesData(place: PlaceOfRequest) async throws {
        guard session.isCurrent(stamp), !Task.isCancelled else { return }
        if place == .start || place == .refresh {
            hasMoreProjects = true
            offset = 0
            projects = dao.getProjects() ?? []
        }
        guard hasMoreProjects, !isLoading else { return }
        let generation = loadGeneration
        isLoading = true
        defer { if generation == loadGeneration { isLoading = false } }
        let response = try await network.performRequest(
            for: .getProjects,
            pathParameters: [:],
            queryItems: [
                API.QueryParams.limit.item(String(PaginationPolicy.pageSize)),
                API.QueryParams.offset.item(String(offset))
            ],
            with: nil,
            modelType: ProjectDataModel.self
        )
        guard session.isCurrent(stamp), !Task.isCancelled, generation == loadGeneration else { return }
        guard response.status else { throw API.NetError.invalidRequest("Projects could not be loaded") }
        reportCacheWrite(dao.saveProjects(response.result.entities, stamp: stamp))
        if offset == 0 { projects = response.result.entities }
        else { projects.append(contentsOf: response.result.entities.filter { new in
            !projects.contains(where: { $0.code == new.code }) }) }
        offset += response.result.entities.count
        hasMoreProjects = offset < response.result.total && !response.result.entities.isEmpty
    }

    func isDeleting(_ code: String) -> Bool { deletingCodes.contains(code) }

    /// Удаление проекта. Проект резервируется до `prepare` (подготовка к уходу, например сохранение
    /// черновиков): повторный вызов во время подготовки или запроса не шлёт второй DELETE.
    @discardableResult
    func deleteProject(
        _ project: Project,
        prepare: () async -> Bool = { true }
    ) async throws(API.NetError) -> DeletionOutcome {
        guard session.isCurrent(stamp) else { throw .invalidRequest("Session ended") }
        guard deletingCodes.insert(project.code).inserted else { return .alreadyInFlight }
        defer { deletingCodes.remove(project.code) }
        guard await prepare() else { return .cancelled }
        guard session.isCurrent(stamp) else { throw .invalidRequest("Session ended") }

        let response = try await network.performRequest(
            for: .deleteProject,
            pathParameters: ["code": project.code],
            queryItems: [],
            with: nil,
            modelType: SharedResponseModel.self
        )
        guard session.isCurrent(stamp) else { throw .invalidRequest("Session ended") }
        guard response.status else { throw .invalidRequest("Project deletion failed") }
        if response.status {
            reportCacheWrite(dao.deleteProject(project, stamp: stamp))
            projects.removeAll { $0.code == project.code }
        }
        return .deleted
    }

    func countOfRows() -> Int { projects.count }
}
