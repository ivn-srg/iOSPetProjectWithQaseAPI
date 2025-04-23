//
//  Projects.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 04.01.2024.
//

import Foundation

struct ProjectDataModel: Codable {
    let status: Bool
    let result: ProjectsResult
}

struct ProjectsResult: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [Project]
}

struct Project: Codable {
    var title: String
    var code: String
    var counts: CountsOfProject?
    var description: String?
    
    var isEmpty: Bool {
        self.title.isEmpty || self.code.isEmpty
    }
    
    init() {
        self.title = ""
        self.code = ""
        self.description = ""
    }
    
    init(realmObject: ProjectRO) {
        title = realmObject.title
        code = realmObject.code
        counts = CountsOfProject(realmObject: realmObject.counts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(code, forKey: .code)
        try container.encode(description, forKey: .description)
    }
}

struct CountsOfProject: Codable {
    let cases: Int
    let suites: Int
    let milestones: Int
    let runs: TestRuns?
    let defects: BugReports?
    
    init?(realmObject: CountsOfProjectRO?) {
        guard let realmObject = realmObject else { return nil }
        
        cases = realmObject.cases
        suites = realmObject.suites
        milestones = realmObject.milestones
        runs = TestRuns(realmObject: realmObject.runs)
        defects = BugReports(realmObject: realmObject.defects)
    }
}

struct TestRuns: Codable {
    let total: Int
    let active: Int
    
    init?(realmObject: TestRunsRO?) {
        guard let realmObject = realmObject else { return nil }
        
        total = realmObject.total
        active = realmObject.active
    }
}

struct BugReports: Codable {
    let total: Int
    let open: Int
    
    init?(realmObject: BugReportsRO?) {
        guard let realmObject = realmObject else { return nil }
        
        total = realmObject.total
        open = realmObject.open
    }
}

struct ProjectErrorDataModel: Codable {
    let error: String
}

// MARK: - Creating a Project
struct CreateOrUpdateProjectModel: Codable {
    let code: String
}
