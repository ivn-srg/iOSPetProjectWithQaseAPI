import Foundation

/// The new read screens share explicit project routing and one session boundary.
@MainActor
final class HomeRepository {
    private let network: NetworkManager
    private let dao: RealmManager?
    private let session: SessionContext
    private let clock: () -> Date
    private let pageSize = 50
    private var projectPageStamp: SessionStamp?
    private var projectPageOffset = 0
    private var fetchedProjects: [ProjectSummary] = []

    init(network: NetworkManager, dao: RealmManager? = nil, session: SessionContext? = nil, clock: @escaping () -> Date = Date.init) {
        self.network = network
        self.dao = dao
        self.session = session ?? .shared
        self.clock = clock
    }

    func listProjects(offset: Int = 0) async throws -> QaseAPIListResult<ProjectSummary> {
        let stamp = session.capture()
        let raw: QaseAPIListResult<ProjectSummary> = try await request(.getProjects, query: pagination(offset), stamp: stamp)
        let cached = dao?.getProjectSummaries() ?? []
        let page = QaseAPIListResult(total: raw.total, filtered: raw.filtered, count: raw.count, entities: raw.entities.map { project in project.mergingDescription(from: cached.first { $0.code == project.code }) })
        if let dao {
            if offset == 0 {
                projectPageStamp = stamp
                projectPageOffset = 0
                fetchedProjects = []
            }
            if projectPageStamp == stamp, offset == projectPageOffset {
                fetchedProjects.append(contentsOf: page.entities)
                projectPageOffset += page.entities.count
                let finished = page.entities.isEmpty || (page.filtered ?? page.total).map { projectPageOffset >= $0 } ?? (page.entities.count < pageSize)
                if finished {
                    _ = dao.replaceProjectSummaries(fetchedProjects, stamp: stamp)
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
            _ = dao.saveProjectSummaries(projects, stamp: stamp)
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
            _ = dao.saveProjectSummaries(projects, stamp: stamp)
            let previous = dao.getHomeSnapshot(projectCode: code)
            _ = dao.saveHomeSnapshot(HomeSnapshot(projectCode: code, activeRun: previous?.activeRun, metricsUpdatedAt: clock(), runUpdatedAt: previous?.runUpdatedAt), stamp: stamp)
        }
        return project
    }

    func activeRun(projectCode: String) async throws -> ActiveRunSummary? {
        let stamp = session.capture()
        var offset = 0
        var candidates: [RunReadDTO] = []
        while true {
            let page: QaseAPIListResult<RunReadDTO> = try await request(
                .getRuns,
                path: ["code": projectCode],
                query: pagination(offset) + [API.QueryParams.status.item("in_progress")],
                stamp: stamp
            )
            candidates.append(contentsOf: page.entities)
            offset += page.entities.count
            guard !page.entities.isEmpty else { break }
            if let total = page.filtered ?? page.total {
                if offset >= total { break }
            } else if page.entities.count < pageSize {
                break
            }
        }
        let active = candidates.sorted(by: Self.mostRecentFirst).first?.summary
        if let dao {
            if !candidates.isEmpty {
                _ = dao.saveRuns(merged(dao.getRuns(projectCode: projectCode) ?? [], with: candidates), projectCode: projectCode, stamp: stamp)
            }
            let previous = dao.getHomeSnapshot(projectCode: projectCode)
            _ = dao.saveHomeSnapshot(HomeSnapshot(projectCode: projectCode, activeRun: active, metricsUpdatedAt: previous?.metricsUpdatedAt, runUpdatedAt: clock()), stamp: stamp)
        }
        return active
    }

    func cases(projectCode: String, query: String = "", offset: Int = 0, suiteID: Int? = nil) async throws -> QaseAPIListResult<CaseSummary> {
        var items = pagination(offset)
        if !query.isEmpty { items.append(API.QueryParams.search.item(query)) }
        if let suiteID { items.append(API.QueryParams.suiteId.item(String(suiteID))) }
        let stamp = session.capture()
        let page: QaseAPIListResult<CaseSummary> = try await request(.getCases, path: ["code": projectCode], query: items, stamp: stamp)
        if let dao {
            let entities = page.entities.map {
                TestListEntity(isSuite: false, id: $0.id, title: $0.title, description: $0.description, parentId: $0.suiteID, casesCount: nil, priority: $0.priority.map(Priority.init), automation: $0.automation.map(AutomationStatus.init))
            }
            _ = dao.saveTestEntities(entities, projectCode: projectCode, stamp: stamp)
        }
        return page
    }

    func suites(projectCode: String, query: String = "", offset: Int = 0) async throws -> QaseAPIListResult<TestListEntity> {
        var items = pagination(offset)
        if !query.isEmpty { items.append(API.QueryParams.search.item(query)) }
        return try await request(.getSuites, path: ["code": projectCode], query: items, stamp: session.capture())
    }

    func runs(projectCode: String, offset: Int = 0) async throws -> QaseAPIListResult<RunReadDTO> {
        let stamp = session.capture()
        let page: QaseAPIListResult<RunReadDTO> = try await request(.getRuns, path: ["code": projectCode], query: pagination(offset), stamp: stamp)
        if let dao { _ = dao.saveRuns(merged(dao.getRuns(projectCode: projectCode) ?? [], with: page.entities), projectCode: projectCode, stamp: stamp) }
        return page
    }

    func run(projectCode: String, id: Int) async throws -> RunReadDTO {
        let stamp = session.capture()
        let run: RunReadDTO = try await request(.getRun, path: ["code": projectCode, "id": String(id)], query: [API.QueryParams.include.item("cases")], stamp: stamp)
        if let dao { _ = dao.saveRun(run, projectCode: projectCode, stamp: stamp) }
        return run
    }

    func defects(projectCode: String, offset: Int = 0) async throws -> QaseAPIListResult<DefectReadDTO> {
        let stamp = session.capture()
        let page: QaseAPIListResult<DefectReadDTO> = try await request(.getDefects, path: ["code": projectCode], query: pagination(offset), stamp: stamp)
        if let dao { _ = dao.saveDefects(merged(dao.getDefects(projectCode: projectCode) ?? [], with: page.entities), projectCode: projectCode, stamp: stamp) }
        return page
    }

    func defect(projectCode: String, id: Int) async throws -> DefectReadDTO {
        let stamp = session.capture()
        let defect: DefectReadDTO = try await request(.getDefect, path: ["code": projectCode, "id": String(id)], stamp: stamp)
        if let dao { _ = dao.saveDefect(defect, projectCode: projectCode, stamp: stamp) }
        return defect
    }

    func cachedCases(projectCode: String) -> [CaseSummary] {
        (dao?.getAllCachedCases(projectCode: projectCode) ?? []).map(CaseSummary.init(entity:))
    }

    func cachedRuns(projectCode: String) -> [RunReadDTO] { dao?.getRuns(projectCode: projectCode) ?? [] }
    func cachedRun(projectCode: String, id: Int) -> RunReadDTO? {
        dao?.getRun(projectCode: projectCode, id: id) ?? cachedRuns(projectCode: projectCode).first { $0.id == id }
    }
    func cachedDefects(projectCode: String) -> [DefectReadDTO] { dao?.getDefects(projectCode: projectCode) ?? [] }
    func cachedDefect(projectCode: String, id: Int) -> DefectReadDTO? {
        dao?.getDefect(projectCode: projectCode, id: id) ?? cachedDefects(projectCode: projectCode).first { $0.id == id }
    }
    func hasCachedRuns(projectCode: String) -> Bool { dao?.getRuns(projectCode: projectCode) != nil }
    func hasCachedDefects(projectCode: String) -> Bool { dao?.getDefects(projectCode: projectCode) != nil }

    private func merged<T: Identifiable>(_ cached: [T], with fetched: [T]) -> [T] {
        let incomingIDs = Set(fetched.map(\.id))
        return cached.filter { !incomingIDs.contains($0.id) } + fetched
    }

    private func request<T: Codable>(_ operation: API.Operation, path: [String: String] = [:], query: [URLQueryItem] = [], stamp: SessionStamp) async throws -> T {
        try Task.checkCancellation()
        let response = try await network.performRequest(for: operation, pathParameters: path, queryItems: query, with: nil, modelType: QaseAPIResponse<T>.self)
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
