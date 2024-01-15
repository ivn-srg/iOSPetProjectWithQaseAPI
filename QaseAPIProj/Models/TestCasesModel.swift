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
    let isFlaky: Int
    let behavior: Int
    let automation: Int
    let status: Int
    let suiteId: Int?
    let links: [String]
    let customFields: [String]
    let attachments: [String]
    let stepsType: String?
    let steps: [StepsInTestCase]
    let params: [String]
    let memberId: Int
    let authorId: Int
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case position
        case title
        case description
        case preconditions
        case postconditions
        case severity
        case priority
        case type
        case layer
        case isFlaky = "is_flaky"
        case behavior
        case automation
        case status
        case suiteId = "suite_id"
        case links
        case customFields = "custom_fields"
        case attachments
        case stepsType = "steps_type"
        case steps
        case params
        case memberId = "member_id"
        case authorId = "author_id"
        case tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Раскодируйте каждое свойство
        id = try container.decode(Int.self, forKey: .id)
        position = try container.decode(Int.self, forKey: .position)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String?.self, forKey: .description)
        preconditions = try container.decode(String?.self, forKey: .preconditions)
        postconditions = try container.decode(String?.self, forKey: .postconditions)
        severity = try container.decode(Int.self, forKey: .severity)
        priority = try container.decode(Int.self, forKey: .priority)
        type = try container.decode(Int.self, forKey: .type)
        layer = try container.decode(Int.self, forKey: .layer)
        isFlaky = try container.decode(Int.self, forKey: .isFlaky)
        behavior = try container.decode(Int.self, forKey: .behavior)
        automation = try container.decode(Int.self, forKey: .automation)
        status = try container.decode(Int.self, forKey: .status)
        suiteId = try container.decode(Int?.self, forKey: .suiteId)
        links = try container.decode([String].self, forKey: .links)
        customFields = try container.decode([String].self, forKey: .customFields)
        attachments = try container.decode([String].self, forKey: .attachments)
        stepsType = try container.decode(String?.self, forKey: .stepsType)
        steps = try container.decode([StepsInTestCase].self, forKey: .steps)
        params = try container.decode([String].self, forKey: .params)
        memberId = try container.decode(Int.self, forKey: .memberId)
        authorId = try container.decode(Int.self, forKey: .authorId)
        tags = try container.decode([String].self, forKey: .tags)
    }
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

struct StepsInTestCase: Codable {
    let hash: String
    let position: Int
    let shared_step_hash: String?
    let shared_step_nested_hash: String?
    let attachments: [Int]
    let action: String?
    let expected_result: String?
    let data: String?
    let steps: [StepsInTestCase]
}
