//
//  TestCasesModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import Foundation

struct TestEntity: Codable {
    let id: Int
    let position: Int
    let title: String
    let description: String?
    let preconditions: String?
    let postconditions: String?
    let severity: Int
    let priority: Int
    let type: Int
    let layer: Int
    let is_flaky: Int
    let behavior: Int
    let automation: Int
    let status: Int
    let milestone_id: Int?
    let suite_id: Int
    let links: [String]
    let custom_fields: [String]
    let attachments: [String]
    let steps_type: String?
    let steps: [String]
    let params: [String]
    let member_id: Int
    let author_id: Int
    let tags: [String]
    let deleted: String?
    let created: String
    let updated: String
    let created_at: String
    let updated_at: String
}

struct TestCasesModel: Codable {
    let status: Bool
    let result: TestResult
}

struct TestResult: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [TestEntity]
}

