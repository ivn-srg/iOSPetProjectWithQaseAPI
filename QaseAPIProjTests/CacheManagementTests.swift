import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@MainActor
struct CacheManagementTests {
    private func store(ownerID: String? = "A") throws -> (SessionContext, RealmManager, Realm) {
        let configuration = Realm.Configuration(
            inMemoryIdentifier: UUID().uuidString,
            objectTypes: RealmManager.cacheObjectTypes
        )
        let session = SessionContext(ownerID: ownerID)
        let dao = RealmManager(configuration: configuration, session: session)
        let realm = try Realm(configuration: configuration)
        return (session, dao, realm)
    }

    private func seedDownloads(owner: String, in realm: Realm) throws -> ProjectRO {
        let project = ProjectRO()
        project.cacheKey = "\(owner)|PROJECT"
        project.ownerID = owner
        project.code = "PROJECT"
        project.title = "Project"
        let counts = CountsOfProjectRO()
        counts.runs = TestRunsRO()
        counts.defects = BugReportsRO()
        project.counts = counts

        let entity = TestListEntity(
            isSuite: true,
            id: 1,
            title: "Suite",
            description: nil,
            parentId: nil,
            casesCount: 1
        )
        let suite = TestEntitiesDataRO(entitiesData: entity, codeOfProject: "PROJECT", ownerID: owner)
        let nested = StepsInTestCase(
            hash: "nested",
            position: 0,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "Nested",
            expectedResult: nil,
            data: nil,
            steps: []
        )
        let middle = StepsInTestCase(
            hash: "middle",
            position: 0,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "Middle",
            expectedResult: nil,
            data: nil,
            steps: [nested]
        )
        var testCase = TestCaseEntity.empty
        testCase.steps = [StepsInTestCase(
            hash: "root",
            position: 0,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "Root",
            expectedResult: nil,
            data: nil,
            steps: [middle]
        )]
        let detail = TestEntityRO(
            testCaseData: testCase,
            reference: TestCaseReference(projectCode: "PROJECT", caseID: 0),
            ownerID: owner
        )
        let home = HomeSnapshotRO()
        home.cacheKey = "\(owner)|PROJECT"
        home.ownerID = owner
        home.projectCode = "PROJECT"
        let read = ReadCacheRO()
        read.cacheKey = "\(owner)|PROJECT|runs"
        read.ownerID = owner
        read.projectCode = "PROJECT"
        try realm.write { realm.add([project, suite, detail, home, read] as [Object]) }
        return project
    }

    @Test(arguments: [0, 1, 2, 3, 4])
    func eachDownloadRootIsDetectedAndCleared(rootIndex: Int) throws {
        let (session, dao, realm) = try store()
        let project = ProjectRO()
        project.ownerID = "A"
        let repository = TestEntitiesDataRO()
        repository.ownerID = "A"
        let detail = TestEntityRO()
        detail.ownerID = "A"
        let home = HomeSnapshotRO()
        home.ownerID = "A"
        let read = ReadCacheRO()
        read.ownerID = "A"
        let roots: [Object] = [project, repository, detail, home, read]
        try realm.write { realm.add(roots[rootIndex]) }
        let stamp = session.capture()
        #expect(try dao.hasDownloadedData(stamp: stamp))
        try dao.clearDownloadedData(stamp: stamp)
        #expect(roots[rootIndex].isInvalidated)
        #expect(try !dao.hasDownloadedData(stamp: stamp))
    }

    @Test func clearingDownloadsPreservesHistoryOtherOwnersAndSession() throws {
        let (session, dao, realm) = try store()
        let ownerProject = try seedDownloads(owner: "A", in: realm)
        let otherProject = try seedDownloads(owner: "B", in: realm)
        let ownerCounts = try #require(ownerProject.counts)
        let ownerRuns = try #require(ownerCounts.runs)
        let ownerDefects = try #require(ownerCounts.defects)
        let otherCounts = try #require(otherProject.counts)
        let history = RecentCaseItem(
            reference: TestCaseReference(projectCode: "PROJECT", caseID: 0),
            title: "Viewed",
            description: nil,
            priority: nil,
            automation: nil,
            viewedAt: Date(timeIntervalSince1970: 1)
        )
        #expect(dao.recordRecentCase(history, stamp: session.capture()))
        session.activate(ownerID: "B")
        #expect(dao.recordRecentCase(history, stamp: session.capture()))
        session.activate(ownerID: "A")
        let stamp = session.capture()

        #expect(try dao.hasDownloadedData(stamp: stamp))
        try dao.clearDownloadedData(stamp: stamp)

        #expect(try !dao.hasDownloadedData(stamp: stamp))
        #expect(realm.objects(ProjectRO.self).filter("ownerID == %@", "A").isEmpty)
        #expect(realm.objects(TestEntitiesDataRO.self).filter("ownerID == %@", "A").isEmpty)
        #expect(realm.objects(TestEntityRO.self).filter("ownerID == %@", "A").isEmpty)
        #expect(realm.objects(HomeSnapshotRO.self).filter("ownerID == %@", "A").isEmpty)
        #expect(realm.objects(ReadCacheRO.self).filter("ownerID == %@", "A").isEmpty)
        #expect(ownerCounts.isInvalidated)
        #expect(ownerRuns.isInvalidated)
        #expect(ownerDefects.isInvalidated)
        #expect(!otherProject.isInvalidated)
        #expect(!otherCounts.isInvalidated)
        #expect(realm.objects(TestEntitiesDataRO.self).filter("ownerID == %@", "B").count == 1)
        #expect(realm.objects(TestEntityRO.self).filter("ownerID == %@", "B").count == 1)
        #expect(realm.objects(HomeSnapshotRO.self).filter("ownerID == %@", "B").count == 1)
        #expect(realm.objects(ReadCacheRO.self).filter("ownerID == %@", "B").count == 1)
        #expect(realm.objects(StepsInTestCaseRO.self).count == 3)
        #expect(realm.objects(StepsInTestCaseRO.self).allSatisfy { $0.entityHash.hasPrefix("B|") })
        #expect(realm.objects(RecentCaseRO.self).count == 2)
        #expect(dao.getRecentCases(projectCode: "PROJECT") == [history])
        #expect(session.capture() == stamp)
    }

    @Test func staleOwnerAndGenerationCannotReadOrClearDownloads() throws {
        let (session, dao, realm) = try store()
        _ = try seedDownloads(owner: "A", in: realm)
        let firstStamp = session.capture()
        session.activate(ownerID: "A")
        #expect(throws: RealmManager.DownloadedDataError.self) {
            _ = try dao.hasDownloadedData(stamp: firstStamp) }
        #expect(throws: RealmManager.DownloadedDataError.self) {
            try dao.clearDownloadedData(stamp: firstStamp) }
        let nextStamp = session.capture()
        session.activate(ownerID: "B")
        #expect(throws: RealmManager.DownloadedDataError.self) {
            _ = try dao.hasDownloadedData(stamp: nextStamp) }
        #expect(throws: RealmManager.DownloadedDataError.self) {
            try dao.clearDownloadedData(stamp: nextStamp) }
        #expect(realm.objects(ProjectRO.self).count == 1)
        #expect(realm.objects(TestEntityRO.self).count == 1)
        #expect(realm.objects(StepsInTestCaseRO.self).count == 3)
    }

    @Test func missingOwnerCannotReadOrClearDownloads() throws {
        let (session, dao, realm) = try store(ownerID: nil)
        _ = try seedDownloads(owner: "A", in: realm)
        let stamp = session.capture()
        #expect(throws: RealmManager.DownloadedDataError.self) { _ = try dao.hasDownloadedData(stamp: stamp) }
        #expect(throws: RealmManager.DownloadedDataError.self) { try dao.clearDownloadedData(stamp: stamp) }
        #expect(realm.objects(ProjectRO.self).count == 1)
        #expect(session.capture() == stamp)
    }

    @Test func emptyCacheClearingIsIdempotentAndHistoryIsNotADownload() throws {
        let (session, dao, _) = try store()
        let stamp = session.capture()
        let history = RecentCaseItem(
            reference: TestCaseReference(projectCode: "PROJECT", caseID: 0),
            title: "Viewed",
            description: nil,
            priority: nil,
            automation: nil,
            viewedAt: Date(timeIntervalSince1970: 1)
        )
        #expect(dao.recordRecentCase(history, stamp: stamp))
        #expect(try !dao.hasDownloadedData(stamp: stamp))
        try dao.clearDownloadedData(stamp: stamp)
        try dao.clearDownloadedData(stamp: stamp)
        #expect(try !dao.hasDownloadedData(stamp: stamp))
        #expect(dao.getRecentCases(projectCode: "PROJECT") == [history])
        #expect(session.capture() == stamp)
        #expect(dao.saveProjectSummaries(
            [ProjectSummary(title: "Downloaded again", code: "PROJECT")],
            stamp: stamp
        ))
        #expect(try dao.hasDownloadedData(stamp: stamp))
    }
}
