import Combine
import Foundation

@MainActor
final class SuitePickerViewModel {
    let projectCode: String
    let projectTitle: String?
    private(set) var selectedID: Int?
    private(set) var catalog: [TestListEntity]
    private(set) var isLoading = false
    private(set) var catalogComplete: Bool
    private(set) var errorMessage: String?
    var query = "" { didSet { onChange?() } }
    var onChange: (() -> Void)?
    private let loader: SuiteCatalogLoader
    private let session: SessionContext
    private let stamp: SessionStamp
    private var generation = 0
    private var invalidation: AnyCancellable?

    var isSessionCurrent: Bool { session.isCurrent(stamp) }
    var filteredSuites: [TestListEntity] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return catalog.filter {
            search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || pathTitle(to: $0.id)
                .localizedCaseInsensitiveContains(search)
        }
    }

    init(
        projectCode: String,
        selectedID: Int? = nil,
        projectTitle: String? = nil,
        network: NetworkManager = ApiServiceConfiguration.shared.apiService,
        dao: RealmManager? = nil,
        session: SessionContext? = nil
    ) {
        let session = session ?? .shared
        let dao = dao ?? .shared
        self.projectCode = projectCode
        self.projectTitle = projectTitle
        self.selectedID = selectedID == 0 ? nil : selectedID
        self.session = session
        stamp = session.capture()
        catalog = dao.getAllCachedSuites(projectCode: projectCode)
        catalogComplete = dao.hasRepositoryCatalog(projectCode: projectCode)
        loader = SuiteCatalogLoader(network: network, dao: dao, session: session)
        invalidation = NotificationCenter.default.publisher(for: .didInvalidateSession)
            .sink { [weak self] notification in
                guard let self, notification.object as AnyObject? === self.session else { return }
                self.cancel()
                self.catalog = []
                self.catalogComplete = false
                self.onChange?()
            }
    }

    func load() async {
        guard isSessionCurrent, !Task.isCancelled else { return }
        generation += 1
        let requestedGeneration = generation
        isLoading = true
        errorMessage = nil
        onChange?()
        defer {
            if requestedGeneration == generation { isLoading = false
                onChange?() }
        }
        do {
            let values = try await loader.load(projectCode: projectCode, isCurrent: { [weak self] in
                self?.accepts(requestedGeneration) == true
            })
            guard accepts(requestedGeneration) else { return }
            catalog = values
            catalogComplete = true
            onChange?()
        } catch {
            guard accepts(requestedGeneration), !(error is CancellationError) else { return }
            errorMessage = "Could not load suites".localized
            onChange?()
        }
    }

    func cancel() {
        generation += 1
        isLoading = false
        onChange?()
    }

    func title(for id: Int?) -> String {
        guard let id, id != 0 else { return "Project root".localized }
        return catalog.first { $0.id == id }?.title ?? "\("Path unavailable".localized) · #\(id)"
    }

    func pathTitle(to id: Int?) -> String {
        guard let breadcrumbs = SuiteCatalogLoader.breadcrumbs(catalog: catalog, suiteID: id) else {
            return "\("Path unavailable".localized) · #\(id ?? 0)"
        }
        var titles = breadcrumbs.map(\.title)
        if let projectTitle, !projectTitle.isEmpty { titles[0] = projectTitle }
        return titles.joined(separator: " › ")
    }

    func ancestorTitle(to id: Int?) -> String {
        guard let breadcrumbs = SuiteCatalogLoader.breadcrumbs(catalog: catalog, suiteID: id) else {
            return "\("Path unavailable".localized) · #\(id ?? 0)"
        }
        guard breadcrumbs.count > 1 else { return projectTitle ?? "Project root".localized }
        var titles = breadcrumbs.dropLast().map(\.title)
        if let projectTitle, !projectTitle.isEmpty { titles[0] = projectTitle }
        return titles.joined(separator: " › ")
    }

    private func accepts(_ value: Int) -> Bool { value == generation && isSessionCurrent && !Task.isCancelled
    }
}
