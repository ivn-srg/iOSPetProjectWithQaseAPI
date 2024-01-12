//
//  Projects.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 04.01.2024.
//

import Foundation

struct ProjectDataModel: Codable {
    let status: Bool
    let result: Result
}

struct Result: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [Project]
}

struct Project: Codable {
    let title: String
    let code: String
    let counts: CountsOfProject
}

struct CountsOfProject: Codable {
    let cases: Int
    let suites: Int
    let milestones: Int
    let runs: TestRuns
    let defects: BugReports
}

struct TestRuns: Codable {
    let total: Int
    let active: Int
}

struct BugReports: Codable {
    let total: Int
    let open: Int
}

struct ProjectErrorDataModel: Codable {
    let error: String
}
