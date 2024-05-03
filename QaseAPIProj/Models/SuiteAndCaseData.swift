//
//  SuiteAndCaseData.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 15.01.2024.
//

import Foundation

final class SuiteAndCaseData {
    let isSuites: Bool
    let id: Int
    let title: String
    let description: String?
    
    // if isSuite
    let parent_id: Int?
    let case_count: Int?
    
    // if !isSuite
    let priority: Int?
    let automation: Int?
    let suiteId: Int?
    
    required init(
        isSuite: Bool,
        id: Int,
        title: String,
        description: String?,
        preconditions: String?,
        parent_id: Int?,
        case_count: Int?,
        priority: Int? = nil,
        automation: Int? = nil,
        suiteId: Int? = nil
    ) {
        self.isSuites = isSuite
        self.id = id
        self.title = title
        self.description = description
        self.parent_id = parent_id
        self.case_count = case_count
        self.priority = priority
        self.automation = automation
        self.suiteId = suiteId
        
    }
}
