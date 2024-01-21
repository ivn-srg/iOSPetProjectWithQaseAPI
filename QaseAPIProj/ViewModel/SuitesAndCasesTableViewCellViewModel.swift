//
//  SuitesAndCasesTableViewCellViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 19.01.2024.
//

import Foundation

class SuitesAndCasesTableViewCellViewModel {
    var isSuite: Bool
    let id: Int
    var title: String
    var description: String?
    var parentId: Int?
    var suiteId: Int?
    var automation: Int?
    var priority: Int?
    
    init(suiteOrCase: SuiteAndCaseData) {
        self.isSuite = suiteOrCase.isSuites
        self.id = suiteOrCase.id
        self.title = suiteOrCase.title
        self.description = suiteOrCase.description
        self.parentId = suiteOrCase.parent_id
        self.suiteId = suiteOrCase.suiteId
        self.automation = suiteOrCase.automation
        self.priority = suiteOrCase.priority
    }
}
