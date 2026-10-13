import Foundation

@MainActor
protocol ProjectsCaching {
    func saveProjects(_ projects: [Project], stamp: SessionStamp) -> Bool
    func getProjects() -> [Project]?
    func deleteProject(_ project: Project, stamp: SessionStamp) -> Bool
    func getProjectSummaries() -> [ProjectSummary]
    func saveProjectSummaries(_ projects: [ProjectSummary], stamp: SessionStamp) -> Bool
    func replaceProjectSummaries(_ projects: [ProjectSummary], stamp: SessionStamp) -> Bool
}

@MainActor
protocol EntityCaching {
    func saveTestEntities(_ entities: [TestListEntity], projectCode: String, stamp: SessionStamp) -> Bool
    func getTestEntities(
        projectCode: String,
        by parentSuite: ParentSuite?,
        testEntitiesType: TargetTestEntities
    ) -> [TestListEntity]?
    func getAllCachedCases(projectCode: String) -> [TestListEntity]
    func deleteEntity(_ entity: TestListEntity, projectCode: String, stamp: SessionStamp) -> Bool
}

@MainActor
protocol TestCaseCaching {
    func saveTestCase(_ testCase: TestCaseEntity, reference: TestCaseReference, stamp: SessionStamp) -> Bool
    func getTestCase(reference: TestCaseReference) -> TestCaseEntity?
    func deleteTestCase(reference: TestCaseReference, stamp: SessionStamp) -> Bool
}

@MainActor
protocol HomeCaching {
    func getHomeSnapshot(projectCode: String) -> HomeSnapshot?
    func saveHomeSnapshot(_ snapshot: HomeSnapshot, stamp: SessionStamp) -> Bool
    func getRecentCases(projectCode: String) -> [RecentCaseItem]
    func recordRecentCase(_ item: RecentCaseItem, stamp: SessionStamp) -> Bool
}

@MainActor
protocol ReadCaching {
    func getRuns(projectCode: String) -> [RunReadDTO]?
    func saveRuns(_ runs: [RunReadDTO], projectCode: String, stamp: SessionStamp) -> Bool
    func getRun(projectCode: String, id: Int) -> RunReadDTO?
    func saveRun(_ run: RunReadDTO, projectCode: String, stamp: SessionStamp) -> Bool
    func getDefects(projectCode: String) -> [DefectReadDTO]?
    func saveDefects(_ defects: [DefectReadDTO], projectCode: String, stamp: SessionStamp) -> Bool
    func getDefect(projectCode: String, id: Int) -> DefectReadDTO?
    func saveDefect(_ defect: DefectReadDTO, projectCode: String, stamp: SessionStamp) -> Bool
}

@MainActor
protocol CacheMaintaining {
    func clearAll() throws
    func useDemoStore(_ enabled: Bool)
    func hasDownloadedData(stamp: SessionStamp) throws -> Bool
    func clearDownloadedData(stamp: SessionStamp) throws
}

@MainActor
protocol RepositoryCaching: EntityCaching {
    func hasRepositoryCatalog(projectCode: String) -> Bool
    func getAllCachedSuites(projectCode: String) -> [TestListEntity]
    func replaceSuiteCatalog(_ suites: [TestListEntity], projectCode: String, stamp: SessionStamp) -> Bool
    func replaceRepositoryCases(
        _ entities: [TestListEntity],
        snapshot: RepositoryLevelSnapshot,
        location: RepositoryLocation,
        stamp: SessionStamp
    ) -> Bool
    func repositorySnapshot(location: RepositoryLocation) -> RepositoryLevelSnapshot?
}

@MainActor
protocol HeroDAO: ProjectsCaching, EntityCaching, TestCaseCaching, HomeCaching {}

@MainActor
protocol HomeRepositoryCache: ProjectsCaching, EntityCaching, HomeCaching, ReadCaching {}

@MainActor
protocol AppCache: HeroDAO, HomeRepositoryCache, RepositoryCaching, CacheMaintaining {}

@MainActor
protocol ProjectsReading {
    func listProjects(offset: Int) async throws -> QaseAPIListResult<ProjectSummary>
}

@MainActor
protocol HomeReading {
    func project(code: String) async throws -> ProjectSummary
    func activeRun(projectCode: String) async throws -> ActiveRunSummary?
}

@MainActor
protocol RepositoryReading {
    func cases(projectCode: String, query: String, offset: Int, suiteID: Int?) async throws
        -> QaseAPIListResult<CaseSummary>
    func suites(projectCode: String, query: String, offset: Int) async throws
        -> QaseAPIListResult<TestListEntity>
}

extension RepositoryReading {
    func cases(
        projectCode: String,
        query: String = "",
        offset: Int = 0,
        suiteID: Int? = nil
    ) async throws -> QaseAPIListResult<CaseSummary> {
        try await cases(projectCode: projectCode, query: query, offset: offset, suiteID: suiteID)
    }

    func suites(
        projectCode: String,
        query: String = "",
        offset: Int = 0
    ) async throws -> QaseAPIListResult<TestListEntity> {
        try await suites(projectCode: projectCode, query: query, offset: offset)
    }
}

@MainActor
protocol WorkReading {
    func runs(projectCode: String, offset: Int) async throws -> QaseAPIListResult<RunReadDTO>
    func run(projectCode: String, id: Int) async throws -> RunReadDTO
    func defects(projectCode: String, offset: Int) async throws -> QaseAPIListResult<DefectReadDTO>
    func defect(projectCode: String, id: Int) async throws -> DefectReadDTO
    func cachedRuns(projectCode: String) -> [RunReadDTO]
    func cachedRun(projectCode: String, id: Int) -> RunReadDTO?
    func cachedDefects(projectCode: String) -> [DefectReadDTO]
    func cachedDefect(projectCode: String, id: Int) -> DefectReadDTO?
    func hasCachedRuns(projectCode: String) -> Bool
    func hasCachedDefects(projectCode: String) -> Bool
}

@MainActor
protocol SuiteCatalogLoading {
    func load(projectCode: String, isCurrent: @MainActor () -> Bool) async throws -> [TestListEntity]
}
