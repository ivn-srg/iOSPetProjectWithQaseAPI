import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@MainActor
struct IdentityCacheTests {
    private func cache(session: SessionContext) -> RealmManager {
        RealmManager(
            configuration: Realm.Configuration(inMemoryIdentifier: UUID().uuidString),
            session: session
        )
    }

    @Test func identicalIDsRemainSeparateAcrossProjects() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        let stamp = session.capture()
        let entity = TestListEntity(
            isSuite: true,
            id: 7,
            title: "Suite",
            description: nil,
            parentId: nil,
            casesCount: 0
        )
        #expect(dao.saveTestEntities([entity], projectCode: "A", stamp: stamp))
        #expect(dao.saveTestEntities([entity], projectCode: "B", stamp: stamp))
        #expect(dao.deleteEntity(entity, projectCode: "A", stamp: stamp))
        #expect(dao.getTestEntities(projectCode: "A", by: nil, testEntitiesType: .all)?.isEmpty == true)
        #expect(dao.getTestEntities(projectCode: "B", by: nil, testEntitiesType: .all)?.count == 1)
    }

    @Test func lateWritesAndPreviousOwnerReadsAreRejected() {
        let session = SessionContext(ownerID: "A")
        let dao = cache(session: session)
        let stamp = session.capture()
        let summary = ProjectSummary(
            title: "Project",
            code: "A",
            metrics: ProjectMetrics(cases: 0, suites: nil, runs: nil, defects: nil)
        )
        #expect(dao.saveProjectSummaries([summary], stamp: stamp))
        session.invalidate()
        session.activate(ownerID: "B")
        #expect(!dao.saveProjectSummaries([summary], stamp: stamp))
        #expect(dao.getProjectSummaries().isEmpty)
    }

    @Test func optionalMetricsSurviveCacheRoundTrip() {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        let summary = ProjectSummary(
            title: "Project",
            code: "A",
            metrics: ProjectMetrics(cases: 0, suites: nil, runs: 2, defects: nil)
        )
        #expect(dao.saveProjectSummaries([summary], stamp: session.capture()))
        #expect(dao.getProjectSummaries().first?.metrics.cases == 0)
        #expect(dao.getProjectSummaries().first?.metrics.suites == nil)
        #expect(dao.getProjectSummaries().first?.metrics.runs == 2)
    }

    @Test func recentHistoryIsDeduplicatedBoundedAndProjectScoped() {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        for id in 1 ... 25 {
            let item = RecentCaseItem(
                reference: TestCaseReference(projectCode: "A", caseID: id),
                title: "Case",
                description: nil,
                priority: nil,
                automation: nil,
                viewedAt: Date(timeIntervalSince1970: Double(id))
            )
            #expect(dao.recordRecentCase(item, stamp: session.capture()))
        }
        #expect(dao.getRecentCases(projectCode: "A").count == 20)
        #expect(dao.getRecentCases(projectCode: "A").first?.reference.caseID == 25)
        #expect(dao.getRecentCases(projectCode: "B").isEmpty)
        let repeated = RecentCaseItem(
            reference: TestCaseReference(projectCode: "A", caseID: 10),
            title: "Updated",
            description: nil,
            priority: nil,
            automation: nil,
            viewedAt: Date(timeIntervalSince1970: 30)
        )
        #expect(dao.recordRecentCase(repeated, stamp: session.capture()))
        #expect(dao.getRecentCases(projectCode: "A").count == 20)
        #expect(dao.getRecentCases(projectCode: "A").first?.title == "Updated")
    }

    @Test func completedProjectRefreshPrunesDeletedProjectCache() {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        let stamp = session.capture()
        let a = ProjectSummary(title: "A", code: "A")
        let b = ProjectSummary(title: "B", code: "B")
        #expect(dao.saveProjectSummaries([a, b], stamp: stamp))
        let entity = TestListEntity(
            isSuite: true,
            id: 1,
            title: "B suite",
            description: nil,
            parentId: nil,
            casesCount: nil
        )
        #expect(dao.saveTestEntities([entity], projectCode: "B", stamp: stamp))
        #expect(dao.replaceProjectSummaries([a], stamp: stamp))
        #expect(dao.getProjectSummaries() == [a])
        #expect(dao.getTestEntities(projectCode: "B", by: nil, testEntitiesType: .all)?.isEmpty == true)
    }

    @Test func cachePersistsWhenAdapterReopens() {
        let session = SessionContext(ownerID: "owner")
        let configuration = Realm.Configuration(inMemoryIdentifier: UUID().uuidString)
        let first = RealmManager(configuration: configuration, session: session)
        let summary = ProjectSummary(title: "Persisted", code: "A", metrics: ProjectMetrics(cases: 0))
        #expect(first.saveProjectSummaries([summary], stamp: session.capture()))
        let reopened = RealmManager(configuration: configuration, session: session)
        #expect(reopened.getProjectSummaries() == [summary])
    }

    @Test func unidentifiedLegacyCacheIsBackedUpAndPurgedOnce() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("cache.realm")
        let legacyConfiguration = Realm.Configuration(
            fileURL: url,
            schemaVersion: 0,
            objectTypes: RealmManager.cacheObjectTypes
        )
        try autoreleasepool {
            let legacy = try Realm(configuration: legacyConfiguration)
            let project = ProjectRO()
            project.code = "LEGACY"
            project.title = "Unidentified"
            project.cacheKey = "LEGACY"
            try legacy.write { legacy.add(project) }
        }
        let session = SessionContext(ownerID: "owner")
        let configuration = RealmManager.migratedConfiguration(legacyConfiguration)
        let dao = RealmManager(configuration: configuration, session: session)
        #expect(dao.getProjectSummaries().isEmpty)
        #expect(FileManager.default.fileExists(atPath: url.appendingPathExtension("legacy-backup").path))
        let project = ProjectSummary(title: "New", code: "A")
        #expect(dao.saveProjectSummaries([project], stamp: session.capture()))
        let reopened = RealmManager(
            configuration: RealmManager.migratedConfiguration(configuration),
            session: session
        )
        #expect(reopened.getProjectSummaries() == [project])
    }

    @Test func actualLegacyStandaloneStepCacheIsPurgedBeforeOwnerScopedSchema() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.realm")
        let configuration = Realm.Configuration(
            fileURL: url,
            schemaVersion: 0,
            objectTypes: [LegacyCacheCase.self, LegacyCacheStep.self]
        )
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            let step = LegacyCacheStep()
            step.entityHash = "shared-hash"
            let a = LegacyCacheCase()
            a.uniqueKey = "1_A"
            a.steps.append(step)
            let b = LegacyCacheCase()
            b.uniqueKey = "1_B"
            b.steps.append(step)
            try realm.write { realm.add([a, b]) }
        }
        let migratedSession = SessionContext(ownerID: "new-owner")
        let migrated = RealmManager(
            configuration: RealmManager.migratedConfiguration(configuration),
            session: migratedSession
        )
        #expect(migrated.initializationError == nil)
        #expect(migrated.getTestCase(reference: TestCaseReference(projectCode: "A", caseID: 1)) == nil)
        let inspection = try Realm(configuration: RealmManager.migratedConfiguration(configuration))
        #expect(!inspection.schema.objectSchema
            .contains {
                $0.className == "QaseLegacyCacheCaseFixture" || $0.className == "QaseLegacyCacheStepFixture"
            })
        #expect(migrated.saveProjectSummaries(
            [ProjectSummary(title: "New", code: "A")],
            stamp: migratedSession.capture()
        ))
        #expect(migrated.getProjectSummaries().first?.code == "A")
    }

    @Test func identicalStepHashesRemainScopedAndDeleteCascadesOnlyOneCase() {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        var a = TestCaseEntity.empty
        var b = TestCaseEntity.empty
        a.steps = [StepsInTestCase(
            hash: "shared",
            position: 0,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "A action",
            expectedResult: nil,
            data: nil,
            steps: []
        )]
        b.steps = [StepsInTestCase(
            hash: "shared",
            position: 0,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "B action",
            expectedResult: nil,
            data: nil,
            steps: []
        )]
        let referenceA = TestCaseReference(projectCode: "A", caseID: 0)
        let referenceB = TestCaseReference(projectCode: "B", caseID: 0)
        #expect(dao.saveTestCase(a, reference: referenceA, stamp: session.capture()))
        #expect(dao.saveTestCase(b, reference: referenceB, stamp: session.capture()))
        #expect(dao.getTestCase(reference: referenceA)?.steps.first?.action == "A action")
        #expect(dao.getTestCase(reference: referenceB)?.steps.first?.hash == "shared")
        #expect(dao.deleteTestCase(reference: referenceA, stamp: session.capture()))
        #expect(dao.getTestCase(reference: referenceB)?.steps.first?.action == "B action")
        a.steps = []
        #expect(dao.saveTestCase(a, reference: referenceB, stamp: session.capture()))
        #expect(dao.getTestCase(reference: referenceB)?.steps.isEmpty == true)
    }

    @Test func runAndDefectCacheIsOwnerAndProjectScoped() throws {
        let session = SessionContext(ownerID: "A")
        let dao = cache(session: session)
        let run = RunReadDTO(id: 1, title: "Run")
        let defect = try JSONDecoder().decode(
            DefectReadDTO.self,
            from: Data("{\"id\":1,\"title\":\"Defect\"}".utf8)
        )
        #expect(dao.saveRuns([run], projectCode: "A", stamp: session.capture()))
        #expect(dao.saveRun(run, projectCode: "A", stamp: session.capture()))
        #expect(dao.saveDefects([defect], projectCode: "A", stamp: session.capture()))
        #expect(dao.saveDefect(defect, projectCode: "A", stamp: session.capture()))
        #expect(dao.getRuns(projectCode: "A") == [run])
        #expect(dao.getRun(projectCode: "A", id: 1) == run)
        #expect(dao.getDefects(projectCode: "A") == [defect])
        #expect(dao.getDefect(projectCode: "A", id: 1) == defect)
        #expect(dao.getRuns(projectCode: "B") == nil)
        session.activate(ownerID: "B")
        #expect(dao.getDefects(projectCode: "A") == nil)
    }

    @Test func initialCaseOpenRecordsHistoryOnceAndEditUsesCapturedProject() async throws {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        let network = IdentityRecordingNetwork()
        let reference = TestCaseReference(projectCode: "A", caseID: 0)
        let vm = DetailTabbarControllerViewModel(
            reference: reference,
            network: network,
            dao: dao,
            session: session,
            clock: { Date(timeIntervalSince1970: 10) }
        )
        try await vm.fetchCaseDataJSON()
        #expect(network.urls.first?.path == "/v1/case/A/0")
        #expect(dao.getRecentCases(projectCode: "A").count == 1)
        vm.changedTestCase?.title = "Edited"
        try await vm.updateTestCaseData()
        #expect(network.urls.last?.path == "/v1/case/A/0")
        #expect(network.methods.last == .patch)
        #expect(dao.getRecentCases(projectCode: "A").first?.viewedAt == Date(timeIntervalSince1970: 10))
    }

    @Test func failedInitialOpenDoesNotRecordHistory() async throws {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        let network = IdentityRecordingNetwork()
        network.caseStatus = false
        let vm = DetailTabbarControllerViewModel(
            reference: TestCaseReference(projectCode: "A", caseID: 0),
            network: network,
            dao: dao,
            session: session
        )
        do { try await vm.fetchCaseDataJSON()
            Issue.record("An unsuccessful case response must fail") }
        catch { }
        #expect(vm.testCase == nil)
        #expect(dao.getRecentCases(projectCode: "A").isEmpty)
    }

    @Test func saveCallbacksCompleteBeforeGuardRestoresUIHandlers() async {
        let session = SessionContext(ownerID: "owner")
        let dao = cache(session: session)
        let detail = DetailTabbarControllerViewModel(
            reference: TestCaseReference(projectCode: "A", caseID: 0),
            dao: dao,
            session: session
        )
        let create = CreateSuiteOrCaseViewModel(projectCode: "A", session: session)
        var callbackCount = 0
        detail.updatingFinishCallback = { callbackCount += 1 }
        create.creatingFinishCallback = { callbackCount += 1 }
        detail.isUploadingSuccess = true
        create.isEntityWasCreated = true
        #expect(callbackCount == 2)
        detail
            .updatingFinishCallback = {
                Issue.record("A restored detail callback fired after save completion") }
        create
            .creatingFinishCallback = {
                Issue.record("A restored creation callback fired after save completion") }
        await Task.yield()
        #expect(callbackCount == 2)
    }

    @Test func layerOnlyChangesRemainUnsavedDrafts() {
        let original = TestCaseEntity.empty
        var changed = original
        changed.layer = .api
        #expect(original != changed)
    }

    @Test func lateLegacyDetailResponseCannotPublishOrCache() async throws {
        let session = SessionContext(ownerID: "A")
        let dao = cache(session: session)
        let network = IdentityRecordingNetwork()
        network.beforeResponse = { session.invalidate()
            session.activate(ownerID: "B") }
        let vm = DetailTabbarControllerViewModel(
            reference: TestCaseReference(projectCode: "PROJECT", caseID: 0),
            network: network,
            dao: dao,
            session: session
        )
        try await vm.fetchCaseDataJSON()
        #expect(vm.testCase == nil)
        #expect(dao.getRecentCases(projectCode: "PROJECT").isEmpty)
        #expect(dao.getTestCase(reference: TestCaseReference(projectCode: "PROJECT", caseID: 0)) == nil)
    }

    @Test func credentialRecordReadsLegacyUTF8AndNewAtomicFormat() throws {
        let legacy = try #require(AuthCredential.decode(Data("token".utf8)))
        #expect(legacy.token == "token")
        let record = AuthCredential(token: "token", ownerID: "owner")
        #expect(AuthCredential.decode(try JSONEncoder().encode(record)) == record)
    }
}

@MainActor
private final class IdentityRecordingNetwork: NetworkManager {
    var urls: [URL] = []
    var methods: [API.HTTPMethod] = []
    var beforeResponse: (() -> Void)?
    var caseStatus = true
    func performRequest<T: Decodable>(
        with data: Encodable?,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        if let urlString { urls.append(urlString) }
        methods.append(method)
        await Task.yield()
        beforeResponse?()
        if modelType == TestCaseModel.self {
            return TestCaseModel(status: caseStatus, result: TestCaseEntity.empty) as! T
        }
        return try API.decodeResponse(
            from: Data("{\"status\":true,\"result\":{\"id\":0}}".utf8),
            as: modelType
        )
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }
    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }
    func composeURL(
        for method: API.Endpoint,
        urlComponents: [String?]?,
        queryItems: [API.QueryParams: Int?]?
    ) -> URL? { APIManager.shared.composeURL(
        for: method,
        urlComponents: urlComponents,
        queryItems: queryItems
    ) }
    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? { APIManager.shared.composeURL(
        for: operation,
        pathParameters: pathParameters,
        queryItems: queryItems
    ) }
    func auth(by token: String) async throws -> Bool { true }
}

@objc(QaseLegacyCacheCaseFixture)
private final class LegacyCacheCase: Object {
    @Persisted(primaryKey: true) var uniqueKey: String
    @Persisted var steps: List<LegacyCacheStep>
}

@objc(QaseLegacyCacheStepFixture)
private final class LegacyCacheStep: Object {
    @Persisted(primaryKey: true) var entityHash: String
}
