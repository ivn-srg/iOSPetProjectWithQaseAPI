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
    let entities: [Entity]
}

struct Entity: Codable {
    let title: String
    let code: String
    let counts: Counts
}

struct Counts: Codable {
    let cases: Int
    let suites: Int
    let milestones: Int
    let runs: Runs
    let defects: Defects
}

struct Runs: Codable {
    let total: Int
    let active: Int
}

struct Defects: Codable {
    let total: Int
    let open: Int
}
