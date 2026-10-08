import Combine
import Foundation

@MainActor
final class SelectedProjectStore: ObservableObject {
    @Published private(set) var selectedProject: ProjectSummary?
    @Published private(set) var projects: [ProjectSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    private let repository: HomeRepository
    private let cache: RealmManager
    private let session: SessionContext
    private let defaults: UserDefaults
    private let originStamp: SessionStamp
    var onSelectionRequested: ((ProjectSummary?) async -> Bool)?
    var onSelectionChanged: (() -> Void)?

    init(repository: HomeRepository, cache: RealmManager, session: SessionContext,
         defaults: UserDefaults = .standard) {
        self.repository = repository
        self.cache = cache
        self.session = session
        self.defaults = defaults
        originStamp = session.capture()
    }

    private var preferenceKey: String {
        "selectedProject." + (session.ownerID ?? "signed-out")
    }

    func load() async {
        guard !isLoading, session.isCurrent(originStamp) else { return }
        let stamp = session.capture()
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        if projects.isEmpty {
            projects = cache.getProjectSummaries()
            await restoreSelection()
        }
        do {
            var fetched: [ProjectSummary] = []
            var offset = 0
            while true {
                let page = try await repository.listProjects(offset: offset)
                guard session.isCurrent(stamp), !Task.isCancelled else { return }
                fetched += page.entities
                offset += page.entities.count
                if page.entities.isEmpty || offset >= (page.filtered ?? page.total ?? offset) { break }
            }
            guard session.isCurrent(stamp) else { return }
            projects = fetched
            await restoreSelection()
        } catch is CancellationError {
        } catch {
            guard session.isCurrent(stamp) else { return }
            errorMessage = "Could not load projects".localized
        }
    }

    func commit(_ project: ProjectSummary?) {
        guard session.isCurrent(originStamp) else { return }
        let changed = selectedProject?.code != project?.code
        selectedProject = project
        if let project {
            defaults.set(project.code, forKey: preferenceKey)
        } else {
            defaults.removeObject(forKey: preferenceKey)
        }
        if changed { onSelectionChanged?() }
    }

    func didDeleteProject(code: String) async {
        guard session.isCurrent(originStamp) else { return }
        projects.removeAll { $0.code == code }
        await restoreSelection()
    }

    func refreshSelection(_ project: ProjectSummary) {
        guard session.isCurrent(originStamp) else { return }
        guard selectedProject?.code == project.code else { return }
        selectedProject = project
        if let index = projects.firstIndex(where: { $0.code == project.code }) { projects[index] = project }
    }

    private func restoreSelection() async {
        let code = selectedProject?.code ?? defaults.string(forKey: preferenceKey)
        let candidate = projects.first(where: { $0.code == code }) ?? projects.first
        if selectedProject != nil && selectedProject?.code != candidate?.code, let request = onSelectionRequested {
            _ = await request(candidate)
        } else {
            commit(candidate)
        }
    }
}
