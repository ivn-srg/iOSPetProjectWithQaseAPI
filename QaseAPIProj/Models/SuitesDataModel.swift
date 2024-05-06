//
//  File.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import Foundation

struct SuitesDataModel: Codable {
    let status: Bool
    let result: SuitesResult
}

struct SuitesResult: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [SuiteEntity]
}

struct SuiteEntity: Codable {
    let id: Int
    let title: String
    let description: String?
    let preconditions: String?
    let position: Int
    let cases_count: Int
    let parent_id: Int?
}

struct ParentSuite {
    let id: Int
    let title: String
    
    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}

