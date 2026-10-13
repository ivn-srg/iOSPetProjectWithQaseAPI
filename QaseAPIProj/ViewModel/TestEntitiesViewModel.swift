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
    private let catalogLoader: SuiteCatalogLoading
    private let repository: RepositoryReading
    private let network: NetworkManager
    private let dao: RepositoryCaching
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
    var showingSavedData: Bool {
        (suiteError != nil && catalogComplete) || (caseError != nil && updatedAt != nil) ||
            (searchError != nil && (!searchedSuites.isEmpty || !searchedCases.isEmpty)) }

    var levelTitle: String {
        catalog.first(where: { $0.id == location.suiteID })?.title ?? parentSuite?.title ?? "Project root"
            .localized }

    @Published private(set) var levelUnavailable = false
    private let onCacheFailure: () -> Void
    private let clock: () -> Date

    init(
        projectCode: String,
        parentSuite: ParentSuite? = nil,
        network: NetworkManager,
        repository: RepositoryReading,
        catalogLoader: SuiteCatalogLoading,
        dao: RepositoryCaching,
        session: SessionContext,
        clock: @escaping () -> Date = Date.init,
        onCacheFailure: @escaping () -> Void = {}
    ) {
        self.onCacheFailure = onCacheFailure
        self.clock = clock
        self.projectCode = projectCode
        self.parentSuite = parentSuite
        self.network = network
        self.dao = dao
        self.session = session
        stamp = self.session.capture()
        self.repository = repository
        self.catalogLoader = catalogLoader
        catalog = self.dao.getAllCachedSuites(projectCode: projectCode)
        catalogComplete = self.dao.hasRepositoryCatalog(projectCode: projectCode)
        let cachedCases = self.dao.getAllCachedCases(projectCode: projectCode)
            .filter { normalized($0.parentId) == location.suiteID }
        if let snapshot = self.dao.repositorySnapshot(location: location) {
            let order = Dictionary(
                snapshot.caseIDs.enumerated().map { ($0.element, $0.offset) },
                uniquingKeysWith: { first, _ in first }
            )
            cases = cachedCases.sorted { (order[$0.id] ?? Int.max) < (order[$1.id] ?? Int.max) }
            caseCount = cases.count
            updatedAt = snapshot.updatedAt
        } else { cases = cachedCases }
        invalidation = NotificationCenter.default.publisher(for: .didInvalidateSession)
            .sink { [weak self] notification in
                guard let self, notification.object as AnyObject? === self.session else { return }
                self.cancel()
                self.catalog = []
                self.cases = []
                self.searchedSuites = []
                self.searchedCases = []
            }
    }

    func cancel() {
        caseGeneration += 1
        catalogGeneration += 1
        searchGeneration += 1
        searchTask?.cancel()
        suitesLoading = false
        casesLoading = false
        searchLoading = false
    }

    func reload() async {
        guard session.isCurrent(stamp) else { return }
        offset = 0
        fetchedCases = []
        hasMoreCases = true
        caseCount = nil
        casesLoading = false
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
        suitesLoading = true
        suiteError = nil
        levelUnavailable = false
        defer { if generation == catalogGeneration { suitesLoading = false } }
        do {
            let values = try await catalogLoader.load(projectCode: projectCode, isCurrent: { [weak self] in
                guard let self else { return false }
                return self.accepts(generation, self.catalogGeneration)
            })
            guard accepts(generation, catalogGeneration) else { return }
            catalog = values
            catalogComplete = true
            if let id = location.suiteID,
               !values
               .contains(where: { $0.id == id }) {
                levelUnavailable = true
                suiteError = "Suite unavailable".localized }
        } catch {
            if accepts(generation, catalogGeneration),
               !(error is CancellationError) { suiteError = "Could not load suites".localized }
        }
    }

    func loadMoreCases() async {
        guard !casesLoading, hasMoreCases, session.isCurrent(stamp) else { return }
        let generation = caseGeneration
        casesLoading = true
        caseError = nil
        defer { if generation == caseGeneration { casesLoading = false } }
        do {
            var found: Bool
            repeat {
                let page = try await repository.cases(
                    projectCode: projectCode,
                    offset: offset,
                    suiteID: location.suiteID
                )
                guard accepts(generation, caseGeneration) else { return }
                let entities = page.entities.map(Self.entity)
                let previousCount = fetchedCases.count
                appendUnique(entities, to: &fetchedCases)
                offset += page.entities.count
                hasMoreCases = PaginationPolicy.hasMore(
                    received: page.entities.count,
                    offset: offset,
                    total: page.filtered ?? page.total
                )
                guard page.entities.isEmpty || fetchedCases.count > previousCount else {
                    hasMoreCases = false
                    throw API.NetError.invalidRequest("The case list did not advance")
                }
                let matching = entities.filter { normalized($0.parentId) == location.suiteID }
                found = !matching.isEmpty
                cases = fetchedCases.filter { normalized($0.parentId) == location.suiteID }
            } while !found && hasMoreCases
            if !hasMoreCases, accepts(generation, caseGeneration) {
                let timestamp = clock()
                reportCacheWrite(dao.replaceRepositoryCases(
                    fetchedCases,
                    snapshot: .init(caseIDs: cases.map(\.id), updatedAt: timestamp),
                    location: location,
                    stamp: stamp
                ))
                caseCount = cases.count
                updatedAt = timestamp
            }
        } catch {
            if accepts(generation, caseGeneration),
               !(error is CancellationError) { caseError = "Could not load cases".localized }
        }
    }

    func queryChanged() {
        searchGeneration += 1
        searchTask?.cancel()
        searchedSuites = []
        searchedCases = []
        searchError = nil
        guard hasQuery else { searchLoading = false
            return }
        searchTask = Task { [weak self] in
            do { try await Task.sleep(for: SearchPolicy.debounce) } catch { return }
            await self?.search(reset: true)
        }
    }

    func search(reset: Bool, suites: Bool = true, cases: Bool = true) async {
        guard hasQuery, session.isCurrent(stamp) else { return }
        if reset {
            searchGeneration += 1
            suiteSearchOffset = 0
            caseSearchOffset = 0
            moreSearchSuites = true
            moreSearchCases = true
        }
        let generation = searchGeneration
        let requestedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchLoading = true
        searchError = nil
        defer { if generation == searchGeneration { searchLoading = false } }
        await withTaskGroup(of: Void.self) { group in
            if suites && moreSearchSuites {
                group.addTask { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let page = try await self.repository.suites(
                            projectCode: self.projectCode,
                            query: requestedQuery,
                            offset: self.suiteSearchOffset
                        )
                        guard self.accepts(generation, self.searchGeneration) else { return }
                        if reset { self.searchedSuites = [] }
                        self.reportCacheWrite(self.dao.saveTestEntities(
                            page.entities,
                            projectCode: self.projectCode,
                            stamp: self.stamp
                        ))
                        self.appendUnique(page.entities, to: &self.searchedSuites)
                        self.suiteSearchOffset += page.entities.count
                        self.moreSearchSuites = PaginationPolicy.hasMore(
                            received: page.entities.count,
                            offset: self.suiteSearchOffset,
                            total: page.filtered ?? page.total
                        )
                    } catch {
                        guard self.accepts(generation, self.searchGeneration),
                              !(error is CancellationError) else { return }
                        self.searchedSuites = self.catalog
                            .filter { $0.title.localizedCaseInsensitiveContains(requestedQuery) }
                        self.moreSearchSuites = false
                        self.searchError = "Search is limited to saved data"
                            .localized
                    }
                }
            }
            if cases && moreSearchCases {
                group.addTask { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let page = try await self.repository.cases(
                            projectCode: self.projectCode,
                            query: requestedQuery,
                            offset: self.caseSearchOffset
                        )
                        guard self.accepts(generation, self.searchGeneration) else { return }
                        if reset { self.searchedCases = [] }
                        var ids = Set(self.searchedCases.map(\.id))
                        self.searchedCases += page.entities.filter { ids.insert($0.id).inserted }
                        self.caseSearchOffset += page.entities.count
                        self.moreSearchCases = PaginationPolicy.hasMore(
                            received: page.entities.count,
                            offset: self.caseSearchOffset,
                            total: page.filtered ?? page.total
                        )
                    } catch {
                        guard self.accepts(generation, self.searchGeneration),
                              !(error is CancellationError) else { return }
                        self.searchedCases = self.dao.getAllCachedCases(projectCode: self.projectCode)
                            .map(CaseSummary.init(entity:))
                            .filter { $0.title.localizedCaseInsensitiveContains(requestedQuery) }
                        self.moreSearchCases = false
                        self.searchError = "Search is limited to saved data"
                            .localized
                    }
                }
            }
        }
    }

    func path(to suiteID: Int?) -> [RepositoryBreadcrumb]? {
        SuiteCatalogLoader.breadcrumbs(catalog: catalog, suiteID: suiteID)
    }

    func pathTitle(to suiteID: Int?) -> String { SuiteCatalogLoader.pathTitle(
        catalog: catalog,
        suiteID: suiteID
    ) }

    func delete(_ reference: RepositoryItemReference) async throws {
        guard session.isCurrent(stamp),
              reference.projectCode == projectCode else { throw CancellationError() }
        let operation: API.Operation = reference.isSuite ? .deleteSuite : .deleteCase
        let response = try await network.performRequest(
            for: operation,
            pathParameters: ["code": projectCode, "id": String(reference.id)],
            queryItems: [],
            with: nil,
            modelType: SharedResponseModel.self
        )
        guard session.isCurrent(stamp) else { throw CancellationError() }
        guard response.status else { throw API.NetError.invalidRequest("Delete failed") }
        let entity = TestListEntity(
            isSuite: reference.isSuite,
            id: reference.id,
            title: "",
            description: nil,
            parentId: nil,
            casesCount: nil
        )
        reportCacheWrite(dao.deleteEntity(entity, projectCode: projectCode, stamp: stamp))
        await reload()
    }

    private func reportCacheWrite(_ accepted: Bool) {
        if !accepted { onCacheFailure() }
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
        .init(
            isSuite: false,
            id: item.id,
            title: item.title,
            description: item.description,
            parentId: item.suiteID == 0 ? nil : item.suiteID,
            casesCount: nil,
            priority: item.priority.map(Priority.init),
            automation: item.automation.map(AutomationStatus.init)
        )
    }
}
