//
//  SuiteAndCaseData.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 15.01.2024.
//

import Foundation

struct SuiteAndCaseData {
    let isSuites: Bool
    let id: Int
    let title: String
    let itemDescription: String?
    
    // if isSuite
    let parentId: Int?
    let caseCount: Int?
    
    // if !isSuite
    let priority: Int?
    let automation: Int?
    let suiteId: Int?
    
    var uniqueKey: String {
        "\(id)_\(isSuites)"
    }
    
    init(
        isSuite: Bool,
        id: Int,
        title: String,
        description: String?,
        preconditions: String?,
        parentId: Int?,
        caseCount: Int?,
        priority: Int? = nil,
        automation: Int? = nil,
        suiteId: Int? = nil
    ) {
        self.isSuites = isSuite
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
        self.id = suiteRO.id
        self.isSuites = suiteRO.isSuites
        self.title = suiteRO.title
        self.itemDescription = suiteRO.itemDescription
        self.parentId = suiteRO.parentId
        self.caseCount = suiteRO.caseCount
        self.priority = suiteRO.priority
        self.automation = suiteRO.automation
        self.suiteId = suiteRO.suiteId
    }
}
