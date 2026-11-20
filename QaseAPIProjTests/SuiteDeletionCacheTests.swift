import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite @MainActor
struct SuiteDeletionCacheTests {
    private func suite(_ id: Int, parent: Int?) -> TestListEntity {
        TestListEntity(
            isSuite: true,
            id: id,
            title: "Suite \(id)",
            description: nil,
            parentId: parent,
            casesCount: 1
        )
    }

    private func caseRow(_ id: Int, in suiteID: Int) -> TestListEntity {
        TestListEntity(
            isSuite: false,
            id: id,
            title: "Case \(id)",
            description: nil,
            parentId: suiteID,
            casesCount: nil
        )
    }

    private func detail(_ id: Int, suiteID: Int?, project: String, owner: String) throws -> TestCaseEntity {
        let fixture = TestEntityRO(
            testCaseData: .empty,
            reference: TestCaseReference(projectCode: project, caseID: id),
            ownerID: owner
        )
        fixture.id = id
        guard var value = TestCaseEntity(realmObject: fixture) else { throw CocoaError(.fileReadUnknown) }
        value.suiteId = suiteID
        return value
    }

    /// Набор 1 (родитель nil) → вложенный 2; набор 3 отдельно. Кейсы 10 (в 1), 11 (в 2), 12 (в 3).
    private func populate(_ dao: RealmManager, session: SessionContext, project: String) throws {
        let owner = try #require(session.ownerID)
        let stamp = session.capture()
        #expect(dao.replaceSuiteCatalog(
            [suite(1, parent: nil), suite(2, parent: 1), suite(3, parent: nil)],
            projectCode: project,
            stamp: stamp
        ))
        for (suiteID, caseID) in [(1, 10), (2, 11), (3, 12)] {
            #expect(dao.replaceRepositoryCases(
                [caseRow(caseID, in: suiteID)],
                snapshot: .init(caseIDs: [caseID], updatedAt: Date(timeIntervalSince1970: 100)),
                location: .init(projectCode: project, suiteID: suiteID),
                stamp: stamp
            ))
            let reference = TestCaseReference(projectCode: project, caseID: caseID)
            let value = try detail(caseID, suiteID: suiteID, project: project, owner: owner)
            #expect(dao.saveTestCase(value, reference: reference, stamp: stamp))
        }
        for caseID in [10, 12] {
            let item = RecentCaseItem(
                reference: TestCaseReference(projectCode: project, caseID: caseID),
                title: "Case \(caseID)",
                description: nil,
                priority: nil,
                automation: nil,
                viewedAt: Date(timeIntervalSince1970: Double(caseID))
            )
            #expect(dao.recordRecentCase(item, stamp: stamp))
        }
    }

    private func suiteIDs(_ dao: RealmManager, _ project: String) -> Set<Int> {
        Set(dao.getAllCachedSuites(projectCode: project).map(\.id))
    }

    private func caseIDs(_ dao: RealmManager, _ project: String) -> Set<Int> {
        Set(dao.getAllCachedCases(projectCode: project).map(\.id))
    }

    private func detailIDs(_ dao: RealmManager, _ project: String) -> Set<Int> {
        Set([10, 11, 12].filter {
            dao.getTestCase(reference: TestCaseReference(projectCode: project, caseID: $0)) != nil
        })
    }

    @Test func deletingSuiteRemovesSubtreeAndKeepsOtherSuitesAndOwners() throws {
        let session = SessionContext(ownerID: "other-owner")
        let dao = TestDependencies.cache(session: session)
        try populate(dao, session: session, project: "A")

        session.invalidate()
        session.activate(ownerID: "owner")
        try populate(dao, session: session, project: "A")
        try populate(dao, session: session, project: "B")

        let root = suite(1, parent: nil)
        #expect(dao.deleteEntity(root, projectCode: "A", stamp: session.capture()))

        #expect(suiteIDs(dao, "A") == [3])
        #expect(caseIDs(dao, "A") == [12])
        #expect(detailIDs(dao, "A") == [12])
        #expect(Set(dao.getRecentCases(projectCode: "A").map(\.reference.caseID)) == [12])
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 1)) == nil)
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 2)) == nil)
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 3)) != nil)

        #expect(suiteIDs(dao, "B") == [1, 2, 3])
        #expect(caseIDs(dao, "B") == [10, 11, 12])
        #expect(detailIDs(dao, "B") == [10, 11, 12])
        #expect(Set(dao.getRecentCases(projectCode: "B").map(\.reference.caseID)) == [10, 12])

        session.invalidate()
        session.activate(ownerID: "other-owner")
        #expect(suiteIDs(dao, "A") == [1, 2, 3])
        #expect(caseIDs(dao, "A") == [10, 11, 12])
        #expect(detailIDs(dao, "A") == [10, 11, 12])
        #expect(Set(dao.getRecentCases(projectCode: "A").map(\.reference.caseID)) == [10, 12])
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 1)) != nil)
    }

    @Test func deletingNestedSuiteKeepsParentAndItsCases() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = TestDependencies.cache(session: session)
        try populate(dao, session: session, project: "A")

        #expect(dao.deleteEntity(suite(2, parent: 1), projectCode: "A", stamp: session.capture()))

        #expect(suiteIDs(dao, "A") == [1, 3])
        #expect(caseIDs(dao, "A") == [10, 12])
        #expect(detailIDs(dao, "A") == [10, 12])
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 2)) == nil)
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 1)) != nil)
    }

    @Test func deletingSuiteRemovesCaseDetailsThatHaveNoCachedListRow() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = TestDependencies.cache(session: session)
        let stamp = session.capture()
        #expect(dao.replaceSuiteCatalog([suite(1, parent: nil)], projectCode: "A", stamp: stamp))
        let reference = TestCaseReference(projectCode: "A", caseID: 10)
        let value = try detail(10, suiteID: 1, project: "A", owner: "owner")
        #expect(dao.saveTestCase(value, reference: reference, stamp: stamp))

        #expect(dao.deleteEntity(suite(1, parent: nil), projectCode: "A", stamp: session.capture()))

        #expect(dao.getTestCase(reference: reference) == nil)
    }

    private func counted(_ id: Int, parent: Int?, cases: Int?) -> TestListEntity {
        TestListEntity(
            isSuite: true,
            id: id,
            title: "Suite \(id)",
            description: nil,
            parentId: parent,
            casesCount: cases
        )
    }

    @Test func subtreeCountSumsDescendantsOfParentWithoutDirectCases() {
        let catalog = [
            counted(1, parent: nil, cases: 0),
            counted(2, parent: 1, cases: 3),
            counted(3, parent: 1, cases: 4),
            counted(4, parent: nil, cases: 100)
        ]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == 7)
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 2, catalog: catalog) == 3)
    }

    @Test func subtreeCountIsUnknownWhenAnyNodeHasNoCount() {
        let catalog = [
            counted(1, parent: nil, cases: 0),
            counted(2, parent: 1, cases: 3),
            counted(3, parent: 1, cases: nil)
        ]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == nil)
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 2, catalog: catalog) == 3)
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 99, catalog: catalog) == nil)
    }

    @Test func subtreeCountSurvivesParentCycle() {
        let catalog = [counted(1, parent: 2, cases: 1), counted(2, parent: 1, cases: 2)]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == 3)
    }

    @Test func subtreeIDsTreatZeroParentAsRootAndSurviveCycles() {
        let catalog = [
            counted(1, parent: 0, cases: 1),
            counted(2, parent: 1, cases: 1),
            counted(3, parent: 2, cases: 1),
            counted(4, parent: 0, cases: 1)
        ]
        #expect(SuiteCatalogLoader.subtreeIDs(of: 1, in: catalog) == [1, 2, 3])
        #expect(SuiteCatalogLoader.subtreeIDs(of: 2, in: catalog) == [2, 3])
        #expect(SuiteCatalogLoader.subtreeIDs(of: 99, in: catalog) == [99])

        let cyclic = [counted(1, parent: 2, cases: 1), counted(2, parent: 1, cases: 1)]
        #expect(SuiteCatalogLoader.subtreeIDs(of: 1, in: cyclic) == [1, 2])
    }

    @Test func subtreeCountTreatsZeroParentAsRoot() {
        let catalog = [
            counted(1, parent: 0, cases: 0),
            counted(2, parent: 1, cases: 3),
            counted(3, parent: 1, cases: 4),
            counted(4, parent: 0, cases: 100)
        ]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == 7)
    }

    @Test func modelReportsSubtreeCountOnlyForCompleteCatalog() {
        let session = SessionContext(ownerID: "owner")
        let dao = TestDependencies.cache(session: session)
        let incomplete = TestDependencies.entities(projectCode: "A", dao: dao, session: session)
        #expect(incomplete.casesCountInSubtree(of: 1) == nil)

        #expect(dao.replaceSuiteCatalog(
            [
                counted(1, parent: nil, cases: 0),
                counted(2, parent: 1, cases: 3),
                counted(3, parent: 1, cases: 4)
            ],
            projectCode: "A",
            stamp: session.capture()
        ))
        let complete = TestDependencies.entities(projectCode: "A", dao: dao, session: session)
        #expect(complete.casesCountInSubtree(of: 1) == 7)
    }
}
