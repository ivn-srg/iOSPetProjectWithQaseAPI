//
//  EntitiesRO.swift
//  MarvelHeroesApp
//
//  Created by Sergey Ivanov on 11.04.2024.
//

import Foundation
import RealmSwift

// MARK: - Project's entities

final class ProjectRO: Object {
    @Persisted var title: String
    @Persisted var code: String
    @Persisted var counts: CountsOfProjectRO
    
    override public static func primaryKey() -> String? {
        "code"
    }
    
    convenience init(projectData: Project) {
        self.init()
        self.code = projectData.code
        self.title = projectData.title
        self.counts = CountsOfProjectRO(countsOfProjectData: projectData.counts)
    }
}

final class CountsOfProjectRO: EmbeddedObject {
    @Persisted var cases: Int
    @Persisted var suites: Int
    @Persisted var milestones: Int
    @Persisted var runs: TestRunsRO
    @Persisted var defects: BugReportsRO
            
    convenience init(countsOfProjectData: CountsOfProject) {
        self.init()
        self.cases = countsOfProjectData.cases
        self.suites = countsOfProjectData.suites
        self.milestones = countsOfProjectData.milestones
        self.runs = TestRunsRO(testRunsData: countsOfProjectData.runs)
        self.defects = BugReportsRO(defectsData: countsOfProjectData.defects)
    }
}

final class TestRunsRO: EmbeddedObject {
    @Persisted var total: Int
    @Persisted var active: Int
            
    convenience init(testRunsData: TestRuns) {
        self.init()
        self.total = testRunsData.total
        self.active = testRunsData.active
    }
}

final class BugReportsRO: EmbeddedObject {
    @Persisted var total: Int
    @Persisted var open: Int
    
    convenience init(defectsData: BugReports) {
        self.init()
        self.total = defectsData.total
        self.open = defectsData.open
    }
}

// MARK: - Cases and Suites entities

final class SuiteAndCaseDataRO: Object {
    @Persisted var isSuites: Bool
    @Persisted var id: Int
    @Persisted var title: String
    @Persisted var itemDescription: String?
    
    // if isSuite
    @Persisted var parentId: Int?
    @Persisted var caseCount: Int?
    
    // if !isSuite
    @Persisted var priority: Int?
    @Persisted var automation: Int?
    @Persisted var suiteId: Int?
    
    override public static func primaryKey() -> String? {
        "id"
    }
    
    convenience init(entitiesData: SuiteAndCaseData) {
        self.init()
        self.id = entitiesData.id
        self.isSuites = entitiesData.isSuites
        self.title = entitiesData.title
        self.itemDescription = entitiesData.itemDescription
        self.parentId = entitiesData.parentId
        self.caseCount = entitiesData.caseCount
        self.priority = entitiesData.priority
        self.automation = entitiesData.automation
        self.suiteId = entitiesData.suiteId
    }
}

// MARK: - Test case

final class TestEntityRO: Object {
    @Persisted var id: Int
    @Persisted var position: Int
    @Persisted var title: String
    @Persisted var itemDescription: String?
    @Persisted var preconditions: String?
    @Persisted var postconditions: String?
    @Persisted var severity: Int
    @Persisted var priority: Int
    @Persisted var type: Int
    @Persisted var layer: Int
    @Persisted var isFlaky: Int
    @Persisted var behavior: Int
    @Persisted var automation: Int
    @Persisted var status: Int
    @Persisted var suiteId: Int?
    @Persisted var links: List<String>
    @Persisted var customFields: List<String>
    @Persisted var attachments: List<String>
    @Persisted var stepsType: String?
    @Persisted var steps: List<StepsInTestCaseRO>
    @Persisted var params: List<String>
    @Persisted var memberId: Int
    @Persisted var authorId: Int
    @Persisted var tags: List<String>
    
    override public static func primaryKey() -> String? {
        "id"
    }
    
    convenience init(testCaseData: TestEntity) {
        self.init()
        self.id = testCaseData.id
        self.position = testCaseData.position
        self.title = testCaseData.title
        self.itemDescription = testCaseData.description
        self.preconditions = testCaseData.preconditions
        self.postconditions = testCaseData.postconditions
        self.severity = testCaseData.severity
        self.priority = testCaseData.priority
        self.type = testCaseData.type
        self.layer = testCaseData.layer
        self.isFlaky = testCaseData.isFlaky
        self.behavior = testCaseData.behavior
        self.automation = testCaseData.automation
        self.status = testCaseData.status
        self.suiteId = testCaseData.suiteId
        self.memberId = testCaseData.memberId
        self.authorId = testCaseData.authorId
    }
}

final class StepsInTestCaseRO: EmbeddedObject {
    @Persisted var testCaseHash: String
    @Persisted var position: Int
    @Persisted var shared_step_hash: String?
    @Persisted var shared_step_nested_hash: String?
    @Persisted var attachments: List<Int>
    @Persisted var action: String?
    @Persisted var expected_result: String?
    @Persisted var data: String?
    @Persisted var steps: List<StepsInTestCaseRO>
}
