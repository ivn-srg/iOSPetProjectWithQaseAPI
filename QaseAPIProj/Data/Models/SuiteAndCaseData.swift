//
//  SuiteAndCaseData.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 15.01.2024.
//

import Foundation

struct TestListEntity {
    let isSuite: Bool
    let id: Int
    let title: String
    let itemDescription: String?
    
    // if isSuite
    let parentId: Int?
    let caseCount: Int?
    
    // if !isSuite
    let priority: Priority?
    let automation: AutomationStatus?
    let suiteId: Int?
    
    var uniqueKey: String {
        "\(id)_\(isSuite)"
    }
    
    init(
        isSuite: Bool, id: Int,
        title: String,  description: String?, parentId: Int?,
        caseCount: Int?, priority: Priority? = nil,
        automation: AutomationStatus? = nil, suiteId: Int? = nil
    ) {
        self.isSuite = isSuite
        self.id = id
        self.title = title
        self.itemDescription = description
        self.parentId = parentId
        self.caseCount = caseCount
        self.priority = priority
        self.automation = automation
        self.suiteId = suiteId
    }
    
    init(suiteRO: SuiteAndCaseDataRO) {
        self.init(
            isSuite: suiteRO.isSuites,
            id: suiteRO.id,
            title: suiteRO.title,
            description: suiteRO.itemDescription,
            parentId: suiteRO.parentId,
            caseCount: suiteRO.caseCount,
            priority: Priority(suiteRO.priority ?? 0),
            automation: AutomationStatus(suiteRO.automation ?? 0),
            suiteId: suiteRO.suiteId
        )
    }
    
    init(suite: SuiteEntity) {
        self.init(
            isSuite: true,
            id: suite.id ?? 0,
            title: suite.title,
            description: suite.itemDescription,
            parentId: suite.parentId,
            caseCount: suite.casesCount
        )
    }
    
    init(testCase: TestEntity) {
        self.init(
            isSuite: false,
            id: testCase.id,
            title: testCase.title,
            description: testCase.description,
            parentId: nil,
            caseCount: nil,
            priority: testCase.priority,
            automation: testCase.automation,
            suiteId: testCase.suiteId
        )
    }
}
