import Foundation

/// The new read screens share explicit project routing and one session boundary.
@MainActor
final class HomeRepository: HomeReading, ProjectsReading, RepositoryReading, WorkReading {
    private let onCacheFailure: () -> Void
    private let network: NetworkManager
    private let dao: HomeRepositoryCache?
    private let originStamp: SessionStamp
    private let session: SessionContext
    private let clock: () -> Date
    private let pageSize = PaginationPolicy.pageSize
    private var projectPageStamp: SessionStamp?
    private var projectPageOffset = 0
    private var fetchedProjects: [ProjectSummary] = []

    private func reportCacheWrite(_ accepted: Bool) {
        if !accepted { onCacheFailure() }
    }

    init(
        network: NetworkManager,
        dao: HomeRepositoryCache? = nil,
        session: SessionContext,
        clock: @escaping () -> Date = Date.init,
        onCacheFailure: @escaping () -> Void = {}
    ) {
        self.onCacheFailure = onCacheFailure
        self.network = network
        self.dao = dao
        self.session = session
        originStamp = session.capture()
        self.clock = clock
    }

    func listProjects(offset: Int = 0) async throws -> QaseAPIListResult<ProjectSummary> {
        let stamp = session.capture()
        let raw: QaseAPIListResult<ProjectSummary> = try await request(
            .getProjects,
            query: pagination(offset),
            stamp: stamp
        )
        let cached = dao?.getProjectSummaries() ?? []
        let page = QaseAPIListResult(
            total: raw.total,
            filtered: raw.filtered,
            count: raw.count,
            entities: raw.entities
                .map { project in project.mergingDescription(from: cached.first { $0.code == project.code }) }
        )
        if let dao {
            if offset == 0 {
                projectPageStamp = stamp
                projectPageOffset = 0
                fetchedProjects = []
            }
            if projectPageStamp == stamp, offset == projectPageOffset {
                fetchedProjects.append(contentsOf: page.entities)
                projectPageOffset += page.entities.count
                let finished = page.entities.isEmpty || (page.filtered ?? page.total)
                    .map { projectPageOffset >= $0 } ?? (page.entities.count < pageSize)
                if finished {
                    reportCacheWrite(dao.replaceProjectSummaries(fetchedProjects, stamp: stamp))
                    projectPageStamp = nil
                    fetchedProjects = []
                    return page
                }
            }
            var projects = dao.getProjectSummaries()
            for project in page.entities {
                projects.removeAll { $0.code == project.code }
                projects.append(project)
            }
            reportCacheWrite(dao.saveProjectSummaries(projects, stamp: stamp))
        }
        return page
    }

    func project(code: String) async throws -> ProjectSummary {
        let stamp = session.capture()
        let raw: ProjectSummary = try await request(.getProject, path: ["code": code], stamp: stamp)
        let project = raw.mergingDescription(from: dao?.getProjectSummaries().first { $0.code == code })
        if let dao {
            var projects = dao.getProjectSummaries().filter { $0.code != project.code }
            projects.append(project)
            reportCacheWrite(dao.saveProjectSummaries(projects, stamp: stamp))
            let previous = dao.getHomeSnapshot(projectCode: code)
            reportCacheWrite(dao.saveHomeSnapshot(
                HomeSnapshot(
                    projectCode: code,
                    activeRun: previous?.activeRun,
                    metricsUpdatedAt: clock(),
                    runUpdatedAt: previous?.runUpdatedAt
                ),
                stamp: stamp
            ))
        }
        return project
    }

    func activeRun(projectCode: String) async throws -> ActiveRunSummary? {
        let stamp = session.capture()
        var offset = 0
        var candidates: [RunReadDTO] = []
        var seen = Set<Int>()
        while true {
            let page: QaseAPIListResult<RunReadDTO> = try await request(
                .getRuns,
                path: ["code": projectCode],
                query: pagination(offset) + [API.QueryParams.status.item("in_progress")],
                stamp: stamp
            )
            let unique = page.entities.filter { seen.insert($0.id).inserted }
            guard page.entities.isEmpty || !unique.isEmpty else {
                throw API.NetError.invalidRequest("The run list did not advance")
            }
            candidates.append(contentsOf: unique)
            offset += page.entities.count
            if !PaginationPolicy.hasMore(
                received: page.entities.count,
                offset: offset,
                total: page.filtered ?? page.total
            ) { break }
        }
        let active = candidates.sorted(by: Self.mostRecentFirst).first?.summary
        if let dao {
            if !candidates.isEmpty {
                reportCacheWrite(dao.saveRuns(
                    merged(dao.getRuns(projectCode: projectCode) ?? [], with: candidates),
                    projectCode: projectCode,
                    stamp: stamp
                ))
            }
            let previous = dao.getHomeSnapshot(projectCode: projectCode)
            reportCacheWrite(dao.saveHomeSnapshot(
                HomeSnapshot(
                    projectCode: projectCode,
                    activeRun: active,
                    metricsUpdatedAt: previous?.metricsUpdatedAt,
                    runUpdatedAt: clock()
                ),
                stamp: stamp
            ))
        }
        return active
    }

    func cases(
        projectCode: String,
        query: String = "",
        offset: Int = 0,
        suiteID: Int? = nil
    ) async throws -> QaseAPIListResult<CaseSummary> {
        var items = pagination(offset)
        if !query.isEmpty { items.append(API.QueryParams.search.item(query)) }
        if let suiteID { items.append(API.QueryParams.suiteId.item(String(suiteID))) }
        let stamp = session.capture()
        let page: QaseAPIListResult<CaseSummary> = try await request(
            .getCases,
            path: ["code": projectCode],
            query: items,
            stamp: stamp
        )
        if let dao {
            let entities = page.entities.map {
                TestListEntity(
                    isSuite: false,
                    id: $0.id,
                    title: $0.title,
                    description: $0.description,
                    parentId: $0.suiteID == 0 ? nil : $0.suiteID,
                    casesCount: nil,
                    priority: $0.priority.map(Priority.init),
                    automation: $0.automation.map(AutomationStatus.init)
                )
            }
            reportCacheWrite(dao.saveTestEntities(entities, projectCode: projectCode, stamp: stamp))
        }
        return page
    }

    func suites(
        projectCode: String,
        query: String = "",
        offset: Int = 0
    ) async throws -> QaseAPIListResult<TestListEntity> {
        var items = pagination(offset)
        if !query.isEmpty { items.append(API.QueryParams.search.item(query)) }
        return try await request(
            .getSuites,
            path: ["code": projectCode],
            query: items,
            stamp: session.capture()
        )
    }

    func runs(projectCode: String, offset: Int = 0) async throws -> QaseAPIListResult<RunReadDTO> {
        let stamp = session.capture()
        let page: QaseAPIListResult<RunReadDTO> = try await request(
            .getRuns,
            path: ["code": projectCode],
            query: pagination(offset),
            stamp: stamp
        )
        if let dao { reportCacheWrite(dao.saveRuns(
            merged(dao.getRuns(projectCode: projectCode) ?? [], with: page.entities),
            projectCode: projectCode,
            stamp: stamp
        )) }
        return page
    }

    func run(projectCode: String, id: Int) async throws -> RunReadDTO {
        let stamp = session.capture()
        let run: RunReadDTO = try await request(
            .getRun,
            path: ["code": projectCode, "id": String(id)],
            query: [API.QueryParams.include.item("cases")],
            stamp: stamp
        )
        if let dao { reportCacheWrite(dao.saveRun(run, projectCode: projectCode, stamp: stamp)) }
        return run
    }

    func defects(projectCode: String, offset: Int = 0) async throws -> QaseAPIListResult<DefectReadDTO> {
        let stamp = session.capture()
        let page: QaseAPIListResult<DefectReadDTO> = try await request(
            .getDefects,
            path: ["code": projectCode],
            query: pagination(offset),
            stamp: stamp
        )
        if let dao { reportCacheWrite(dao.saveDefects(
            merged(dao.getDefects(projectCode: projectCode) ?? [], with: page.entities),
            projectCode: projectCode,
            stamp: stamp
        )) }
        return page
    }

    func defect(projectCode: String, id: Int) async throws -> DefectReadDTO {
        let stamp = session.capture()
        let defect: DefectReadDTO = try await request(
            .getDefect,
            path: ["code": projectCode, "id": String(id)],
            stamp: stamp
        )
        if let dao { reportCacheWrite(dao.saveDefect(defect, projectCode: projectCode, stamp: stamp)) }
        return defect
    }

    func cachedCases(projectCode: String) -> [CaseSummary] {
        guard session.isCurrent(originStamp) else { return [] }
        return (dao?.getAllCachedCases(projectCode: projectCode) ?? []).map(CaseSummary.init(entity:))
    }

    func cachedRuns(projectCode: String) -> [RunReadDTO] {
        guard session.isCurrent(originStamp) else { return [] }
        return dao?.getRuns(projectCode: projectCode) ?? []
    }

    func cachedRun(projectCode: String, id: Int) -> RunReadDTO? {
        guard session.isCurrent(originStamp) else { return nil }
        return dao?.getRun(projectCode: projectCode, id: id) ?? cachedRuns(projectCode: projectCode)
            .first { $0.id == id }
    }

    func cachedDefects(projectCode: String) -> [DefectReadDTO] {
        guard session.isCurrent(originStamp) else { return [] }
        return dao?
            .getDefects(projectCode: projectCode) ?? []
    }

    func cachedDefect(projectCode: String, id: Int) -> DefectReadDTO? {
        guard session.isCurrent(originStamp) else { return nil }
        return dao?.getDefect(projectCode: projectCode, id: id) ?? cachedDefects(projectCode: projectCode)
            .first { $0.id == id }
    }

    func hasCachedRuns(projectCode: String) -> Bool {
        guard session.isCurrent(originStamp) else { return false }
        return dao?.getRuns(projectCode: projectCode) != nil
    }

    func hasCachedDefects(projectCode: String) -> Bool {
        guard session.isCurrent(originStamp) else { return false }
        return dao?.getDefects(projectCode: projectCode) != nil
    }

    private func merged<T: Identifiable>(_ cached: [T], with fetched: [T]) -> [T] {
        let incomingIDs = Set(fetched.map(\.id))
        return cached.filter { !incomingIDs.contains($0.id) } + fetched
    }

    private func request<T: Codable>(
        _ operation: API.Operation,
        path: [String: String] = [:],
        query: [URLQueryItem] = [],
        stamp: SessionStamp
    ) async throws -> T {
        try Task.checkCancellation()
        guard session.isCurrent(originStamp) else { throw CancellationError() }
        let response = try await network.performRequest(
            for: operation,
            pathParameters: path,
            queryItems: query,
            with: nil,
            modelType: QaseAPIResponse<T>.self
        )
        try Task.checkCancellation()
        guard session.isCurrent(stamp) else { throw CancellationError() }
        guard let result = response.result, response.status?.value != false else {
            throw API.NetError.parsingError("Qase response did not contain a successful result.")
        }
        return result
    }

    private func pagination(_ offset: Int) -> [URLQueryItem] {
        [API.QueryParams.limit.item(String(pageSize)), API.QueryParams.offset.item(String(max(0, offset)))]
    }

    private static func mostRecentFirst(_ left: RunReadDTO, _ right: RunReadDTO) -> Bool {
        switch (left.startTime, right.startTime) {
        case let (leftDate?, rightDate?) where leftDate != rightDate:
            return leftDate > rightDate
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            return left.id > right.id
        }
    }
}
