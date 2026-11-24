import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
struct ProjectCountsCacheTests {
    private static let legacyWithCounts = #"""
    {"title":"A","code":"A","counts":{"cases":5,"suites":1,"milestones":4,
    "runs":{"total":2,"active":3},"defects":{"total":1,"open":2}}}
    """#

    private func makeCache() -> (dao: RealmManager, session: SessionContext) {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        return (dao, session)
    }

    private func legacyProject(_ json: String) throws -> Project {
        try JSONDecoder().decode(Project.self, from: Data(json.utf8))
    }

    private func summary(_ json: String) throws -> ProjectSummary {
        try JSONDecoder().decode(ProjectSummary.self, from: Data(json.utf8))
    }

    @Test("Summary without active/open/milestones keeps the cached values next to fresh totals")
    func summaryWithoutExtrasKeepsPreviousValues() throws {
        let (dao, session) = makeCache()
        let legacy = try legacyProject(Self.legacyWithCounts)
        #expect(dao.saveProjects([legacy], stamp: session.capture()))
        let fresh = try summary(
            #"{"title":"A","code":"A","counts":{"cases":5,"suites":1,"runs":{"total":7},"defects":{"total":9}}}"#
        )
        #expect(dao.saveProjectSummaries([fresh], stamp: session.capture()))
        let counts = dao.getProjects()?.first?.counts
        #expect(counts?.cases == 5)
        #expect(counts?.runs?.total == 7)
        #expect(counts?.runs?.active == 3)
        #expect(counts?.defects?.total == 9)
        #expect(counts?.defects?.open == 2)
        #expect(counts?.milestones == 4)
    }

    @Test("Fresh active and milestones from the server replace the cached ones")
    func freshValuesWin() throws {
        let (dao, session) = makeCache()
        let legacy = try legacyProject(Self.legacyWithCounts)
        #expect(dao.saveProjects([legacy], stamp: session.capture()))
        let fresh = try summary(
            #"""
            {"title":"A","code":"A","counts":{"cases":5,"suites":1,"milestones":6,
            "runs":{"total":7,"active":1},"defects":{"total":9,"open":8}}}
            """#
        )
        #expect(dao.saveProjectSummaries([fresh], stamp: session.capture()))
        let counts = dao.getProjects()?.first?.counts
        #expect(counts?.runs?.total == 7)
        #expect(counts?.runs?.active == 1)
        #expect(counts?.defects?.total == 9)
        #expect(counts?.defects?.open == 8)
        #expect(counts?.milestones == 6)
    }

    @Test("Summary without runs and defects keeps both cached groups intact")
    func missingRunsAndDefectsAreKept() throws {
        let (dao, session) = makeCache()
        let legacy = try legacyProject(Self.legacyWithCounts)
        #expect(dao.saveProjects([legacy], stamp: session.capture()))
        let fresh = try summary(#"{"title":"A","code":"A","counts":{"cases":42}}"#)
        #expect(dao.saveProjectSummaries([fresh], stamp: session.capture()))
        let counts = dao.getProjects()?.first?.counts
        #expect(counts?.cases == 42)
        #expect(counts?.runs?.total == 2)
        #expect(counts?.runs?.active == 3)
        #expect(counts?.defects?.total == 1)
        #expect(counts?.defects?.open == 2)
        #expect(counts?.milestones == 4)
        let metrics = dao.getProjectSummaries().first?.metrics
        #expect(metrics?.runs == 2)
        #expect(metrics?.defects == 1)
    }

    @Test("The replacing summary writer also preserves active, open and milestones")
    func replaceWriterPreservesExtras() throws {
        let (dao, session) = makeCache()
        let legacy = try legacyProject(Self.legacyWithCounts)
        #expect(dao.saveProjects([legacy], stamp: session.capture()))
        let fresh = try summary(
            #"{"title":"A","code":"A","counts":{"cases":5,"suites":1,"runs":{"total":7},"defects":{"total":9}}}"#
        )
        #expect(dao.replaceProjectSummaries([fresh], stamp: session.capture()))
        let counts = dao.getProjects()?.first?.counts
        #expect(counts?.runs?.total == 7)
        #expect(counts?.runs?.active == 3)
        #expect(counts?.defects?.total == 9)
        #expect(counts?.defects?.open == 2)
        #expect(counts?.milestones == 4)
    }

    @Test("A legacy project without counts does not erase cached counters")
    func legacyWithoutCountsKeepsPreviousCounters() throws {
        let (dao, session) = makeCache()
        let legacy = try legacyProject(Self.legacyWithCounts)
        #expect(dao.saveProjects([legacy], stamp: session.capture()))
        let withoutCounts = try legacyProject(#"{"title":"A2","code":"A"}"#)
        #expect(dao.saveProjects([withoutCounts], stamp: session.capture()))
        let project = dao.getProjects()?.first
        #expect(project?.title == "A2")
        #expect(project?.counts?.cases == 5)
        #expect(project?.counts?.suites == 1)
        #expect(project?.counts?.milestones == 4)
        #expect(project?.counts?.runs?.total == 2)
        #expect(project?.counts?.runs?.active == 3)
        #expect(project?.counts?.defects?.total == 1)
        #expect(project?.counts?.defects?.open == 2)
    }

    @Test("A cached summary with metrics but no new fields decodes with nil extras")
    func metricsKeyWithoutNewFieldsDecodes() throws {
        let decoded = try summary(#"{"title":"A","code":"A","metrics":{"cases":1}}"#)
        #expect(decoded.metrics.cases == 1)
        #expect(decoded.metrics.activeRuns == nil)
        #expect(decoded.metrics.openDefects == nil)
        #expect(decoded.metrics.milestones == nil)
    }

    @Test("Counts of an API response decode active, open and milestones")
    func countsDecodeExtras() throws {
        let decoded = try summary(Self.legacyWithCounts)
        #expect(decoded.metrics.runs == 2)
        #expect(decoded.metrics.activeRuns == 3)
        #expect(decoded.metrics.defects == 1)
        #expect(decoded.metrics.openDefects == 2)
        #expect(decoded.metrics.milestones == 4)
    }
}
