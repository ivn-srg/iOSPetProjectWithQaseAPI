import Foundation

@MainActor
final class ProjectsViewModel {
    weak var delegate: UpdateTableViewProtocol?
    var projects: [Project] = [] { didSet { delegate?.updateTableView() } }
    var isLoading = false
    private var hasMoreProjects = true
    private var offset = 0
    private let network: NetworkManager
    private let dao: HeroDAO
    private let session: SessionContext
    private let stamp: SessionStamp

    init(network: NetworkManager = ApiServiceConfiguration.shared.apiService, dao: HeroDAO? = nil, session: SessionContext? = nil) {
        let session = session ?? .shared
        self.network = network; self.dao = dao ?? RealmManager.shared; self.session = session; self.stamp = session.capture()
    }

    func requestEntitiesData(place: PlaceOfRequest) async throws {
        guard session.isCurrent(stamp) else { return }
        if place == .start || place == .refresh {
            hasMoreProjects = true; offset = 0
            projects = dao.getProjects() ?? []
        }
        guard hasMoreProjects, !isLoading,
              let url = network.composeURL(for: .project, urlComponents: nil, queryItems: [.limit: 50, .offset: offset]) else { return }
        isLoading = true
        LoadingIndicator.startLoading()
        defer { isLoading = false; if session.isCurrent(stamp) { LoadingIndicator.stopLoading() } }
        let response = try await network.performRequest(with: nil, from: url, method: .get, modelType: ProjectDataModel.self)
        guard session.isCurrent(stamp) else { return }
        guard response.status else { throw API.NetError.invalidRequest("Projects could not be loaded") }
        _ = dao.saveProjects(response.result.entities, stamp: stamp)
        if offset == 0 { projects = response.result.entities }
        else { projects.append(contentsOf: response.result.entities.filter { new in !projects.contains(where: { $0.code == new.code }) }) }
        offset += response.result.entities.count
        hasMoreProjects = offset < response.result.total && !response.result.entities.isEmpty
    }

    func deleteProject(_ project: Project) async throws(API.NetError) {
        guard session.isCurrent(stamp) else { throw .invalidRequest("Session ended") }
        guard let url = network.composeURL(for: .project, urlComponents: [project.code], queryItems: nil) else { throw .invalidURL }
        LoadingIndicator.startLoading(); defer { if session.isCurrent(stamp) { LoadingIndicator.stopLoading() } }
        let response = try await network.performRequest(with: nil, from: url, method: .delete, modelType: SharedResponseModel.self)
        guard session.isCurrent(stamp) else { throw .invalidRequest("Session ended") }
        guard response.status else { throw .invalidRequest("Project deletion failed") }
        if response.status {
            _ = dao.deleteProject(project, stamp: stamp)
            projects.removeAll { $0.code == project.code }
        }
    }
    func countOfRows() -> Int { projects.count }
}
