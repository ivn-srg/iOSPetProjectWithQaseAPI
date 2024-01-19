//
//  ProjectsTableViewCell.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 19.01.2024.
//

import Foundation

class ProjectTableCellViewModel {
    var title: String
    var code: String
    var caseCount: Int
    var suiteCount: Int
    var activeRunsCount: Int
    
    init(project: Project) {
        self.title = project.title
        self.code = project.code
        self.caseCount = project.counts.cases
        self.suiteCount = project.counts.suites
        self.activeRunsCount = project.counts.runs.active
    }
}
