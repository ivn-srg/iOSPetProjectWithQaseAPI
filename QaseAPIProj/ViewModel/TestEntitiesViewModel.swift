import Combine
import Foundation

@MainActor
final class TestEntitiesViewModel: ObservableObject {
    let projectCode: String
    let parentSuite: ParentSuite?
    var location: RepositoryLocation { .init(projectCode: projectCode, suiteID: parentSuite?.id) }
    @Published private(set) var catalogComplete = false
    @Published private(set) var catalog: [TestListEntity] = []
    @Published private(set) var cases: [TestListEntity] = []
    @Published private(set) var suitesLoading = false
    @Published private(set) var casesLoading = false
    @Published private(set) var suiteError: String?
    @Published private(set) var caseError: String?
    @Published private(set) var caseCount: Int?
    @Published private(set) var updatedAt: Date?
    @Published var query = ""
    @Published var requestSearchFocus = false
    @Published private(set) var searchedSuites: [TestListEntity] = []
    @Published private(set) var searchedCases: [CaseSummary] = []
    @Published private(set) var searchLoading = false
    @Published private(set) var searchError: String?
    @Published private(set) var moreSearchSuites = false
    @Published private(set) var moreSearchCases = false
    @Published private(set) var hasMoreCases = true
    private let catalogLoader: SuiteCatalogLoader
    private let repository: HomeRepository
    private let network: NetworkManager
    private let dao: RealmManager
    private let session: SessionContext
    private let stamp: SessionStamp
    private var offset = 0
    private var fetchedCases: [TestListEntity] = []
    private var caseGeneration = 0
    private var catalogGeneration = 0
    private var searchGeneration = 0
    private var suiteSearchOffset = 0
    private var caseSearchOffset = 0
    private var searchTask: Task<Void, Never>?
    private var invalidation: AnyCancellable?

    var childSuites: [TestListEntity] { catalog.filter { normalized($0.parentId) == location.suiteID } }
    var testEntitiesData: [TestListEntity] { childSuites + cases }
    var isLoading: Bool { suitesLoading || casesLoading }
    var hasQuery: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var showingSavedData: Bool { (suiteError != nil && catalogComplete) || (caseError != nil && updatedAt != nil) || (searchError != nil && (!searchedSuites.isEmpty || !searchedCases.isEmpty)) }
    var levelTitle: String { catalog.first(where: { $0.id == location.suiteID })?.title ?? parentSuite?.title ?? "Project root".localized }
    var levelUnavailable: Bool { location.suiteID != nil && !suitesLoading && suiteError == "Suite unavailable".localized }

    init(projectCode: String, parentSuite: ParentSuite? = nil, network: NetworkManager = ApiServiceConfiguration.shared.apiService,
         dao: RealmManager? = nil, session: SessionContext? = nil) {
        self.projectCode = projectCode
        self.parentSuite = parentSuite
        self.network = network
        self.dao = dao ?? .shared
        self.session = session ?? .shared
        stamp = self.session.capture()
        repository = HomeRepository(network: network, session: self.session)
        catalogLoader = SuiteCatalogLoader(network: network, dao: self.dao, session: self.session)
        catalog = self.dao.getAllCachedSuites(projectCode: projectCode)
        catalogComplete = self.dao.hasRepositoryCatalog(projectCode: projectCode)
        let cachedCases = self.dao.getAllCachedCases(projectCode: projectCode).filter { normalized($0.parentId) == location.suiteID }
        if let snapshot = self.dao.repositorySnapshot(location: location) {
            let order = Dictionary(snapshot.caseIDs.enumerated().map { ($0.element, $0.offset) }, uniquingKeysWith: { first, _ in first })
            cases = cachedCases.sorted { (order[$0.id] ?? Int.max) < (order[$1.id] ?? Int.max) }
            caseCount = cases.count
            updatedAt = snapshot.updatedAt
        } else { cases = cachedCases }
        invalidation = NotificationCenter.default.publisher(for: .didInvalidateSession).sink { [weak self] notification in
            guard let self, notification.object as AnyObject? === self.session else { return }
            self.cancel()
            self.catalog = []; self.cases = []; self.searchedSuites = []; self.searchedCases = []
        }
    }

    func cancel() {
        caseGeneration += 1; catalogGeneration += 1; searchGeneration += 1
        searchTask?.cancel()
        suitesLoading = false; casesLoading = false; searchLoading = false
    }

    func reload() async {
        guard session.isCurrent(stamp) else { return }
        offset = 0; fetchedCases = []; hasMoreCases = true; caseCount = nil; casesLoading = false
        caseGeneration += 1
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor [weak self] in await self?.loadCatalog() }
            group.addTask { @MainActor [weak self] in await self?.loadMoreCases() }
        }
        if hasQuery { await search(reset: true) }
    }

    private func loadCatalog() async {
        catalogGeneration += 1
        let generation = catalogGeneration
        suitesLoading = true; suiteError = nil
        defer { if generation == catalogGeneration { suitesLoading = false } }
        do {
            let values = try await catalogLoader.load(projectCode: projectCode, isCurrent: { [weak self] in
                guard let self else { return false }
                return self.accepts(generation, self.catalogGeneration)
            })
            guard accepts(generation, catalogGeneration) else { return }
            catalog = values
            catalogComplete = true
            if let id = location.suiteID, !values.contains(where: { $0.id == id }) { suiteError = "Suite unavailable".localized }
        } catch {
            if accepts(generation, catalogGeneration), !(error is CancellationError) { suiteError = "Could not load suites".localized }
        }
    }

    func loadMoreCases() async {
        guard !casesLoading, hasMoreCases, session.isCurrent(stamp) else { return }
        let generation = caseGeneration
        casesLoading = true; caseError = nil
        defer { if generation == caseGeneration { casesLoading = false } }
        do {
            var found: Bool
            repeat {
                let page = try await repository.cases(projectCode: projectCode, offset: offset, suiteID: location.suiteID)
                guard accepts(generation, caseGeneration) else { return }
                let entities = page.entities.map(Self.entity)
                _ = dao.saveTestEntities(entities, projectCode: projectCode, stamp: stamp)
                appendUnique(entities, to: &fetchedCases)
                offset += page.entities.count
                hasMoreCases = !page.entities.isEmpty && offset < (page.filtered ?? page.total ?? offset)
                let matching = entities.filter { normalized($0.parentId) == location.suiteID }
                found = !matching.isEmpty
                cases = fetchedCases.filter { normalized($0.parentId) == location.suiteID }
            } while !found && hasMoreCases
            if !hasMoreCases, accepts(generation, caseGeneration) {
                _ = dao.replaceRepositoryCases(fetchedCases, location: location, stamp: stamp)
                caseCount = cases.count
                updatedAt = Date()
                _ = dao.saveRepositorySnapshot(.init(caseIDs: cases.map(\.id), updatedAt: updatedAt!), location: location, stamp: stamp)
            }
        } catch {
            if accepts(generation, caseGeneration), !(error is CancellationError) { caseError = "Could not load cases".localized }
        }
    }

    func queryChanged() {
        searchGeneration += 1; searchTask?.cancel()
        searchedSuites = []; searchedCases = []; searchError = nil
        guard hasQuery else { searchLoading = false; return }
        searchTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            await self?.search(reset: true)
        }
    }

    func search(reset: Bool, suites: Bool = true, cases: Bool = true) async {
        guard hasQuery, session.isCurrent(stamp) else { return }
        if reset {
            searchGeneration += 1; suiteSearchOffset = 0; caseSearchOffset = 0
            moreSearchSuites = true; moreSearchCases = true
        }
        let generation = searchGeneration
        let requestedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchLoading = true; searchError = nil
        defer { if generation == searchGeneration { searchLoading = false } }
        await withTaskGroup(of: Void.self) { group in
            if suites && moreSearchSuites {
                group.addTask { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let page = try await self.repository.suites(projectCode: self.projectCode, query: requestedQuery, offset: self.suiteSearchOffset)
                        guard self.accepts(generation, self.searchGeneration) else { return }
                        if reset { self.searchedSuites = [] }
                        _ = self.dao.saveTestEntities(page.entities, projectCode: self.projectCode, stamp: self.stamp)
                        self.appendUnique(page.entities, to: &self.searchedSuites)
                        self.suiteSearchOffset += page.entities.count
                        self.moreSearchSuites = !page.entities.isEmpty && self.suiteSearchOffset < (page.filtered ?? page.total ?? self.suiteSearchOffset)
                    } catch {
                        guard self.accepts(generation, self.searchGeneration), !(error is CancellationError) else { return }
                        self.searchedSuites = self.catalog.filter { $0.title.localizedCaseInsensitiveContains(requestedQuery) }
                        self.moreSearchSuites = false; self.searchError = "Search is limited to saved data".localized
                    }
                }
            }
            if cases && moreSearchCases {
                group.addTask { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let page = try await self.repository.cases(projectCode: self.projectCode, query: requestedQuery, offset: self.caseSearchOffset)
                        guard self.accepts(generation, self.searchGeneration) else { return }
                        if reset { self.searchedCases = [] }
                        _ = self.dao.saveTestEntities(page.entities.map(Self.entity), projectCode: self.projectCode, stamp: self.stamp)
                        var ids = Set(self.searchedCases.map(\.id))
                        self.searchedCases += page.entities.filter { ids.insert($0.id).inserted }
                        self.caseSearchOffset += page.entities.count
                        self.moreSearchCases = !page.entities.isEmpty && self.caseSearchOffset < (page.filtered ?? page.total ?? self.caseSearchOffset)
                    } catch {
                        guard self.accepts(generation, self.searchGeneration), !(error is CancellationError) else { return }
                        self.searchedCases = self.dao.getAllCachedCases(projectCode: self.projectCode).map(CaseSummary.init(entity:)).filter { $0.title.localizedCaseInsensitiveContains(requestedQuery) }
                        self.moreSearchCases = false; self.searchError = "Search is limited to saved data".localized
                    }
                }
            }
        }
    }

    func path(to suiteID: Int?) -> [RepositoryBreadcrumb]? {
        SuiteCatalogLoader.breadcrumbs(catalog: catalog, suiteID: suiteID)
    }

    func pathTitle(to suiteID: Int?) -> String { SuiteCatalogLoader.pathTitle(catalog: catalog, suiteID: suiteID) }

    func delete(_ reference: RepositoryItemReference) async throws {
        guard session.isCurrent(stamp), reference.projectCode == projectCode else { throw CancellationError() }
        let operation: API.Operation = reference.isSuite ? .deleteSuite : .deleteCase
        let response = try await network.performRequest(for: operation, pathParameters: ["code": projectCode, "id": String(reference.id)], queryItems: [], with: nil, modelType: SharedResponseModel.self)
        guard session.isCurrent(stamp) else { throw CancellationError() }
        guard response.status else { throw API.NetError.invalidRequest("Delete failed") }
        let entity = TestListEntity(isSuite: reference.isSuite, id: reference.id, title: "", description: nil, parentId: nil, casesCount: nil)
        _ = dao.deleteEntity(entity, projectCode: projectCode, stamp: stamp)
        await reload()
    }

    private func accepts(_ generation: Int, _ current: Int) -> Bool {
        generation == current && session.isCurrent(stamp) && !Task.isCancelled
    }
    private func normalized(_ value: Int?) -> Int? { value == 0 ? nil : value }
    private func appendUnique(_ incoming: [TestListEntity], to values: inout [TestListEntity]) {
        var ids = Set(values.map(\.id))
        values += incoming.filter { ids.insert($0.id).inserted }
    }
    private static func entity(_ item: CaseSummary) -> TestListEntity {
        .init(isSuite: false, id: item.id, title: item.title, description: item.description, parentId: item.suiteID == 0 ? nil : item.suiteID,
              casesCount: nil, priority: item.priority.map(Priority.init), automation: item.automation.map(AutomationStatus.init))
    }
}
