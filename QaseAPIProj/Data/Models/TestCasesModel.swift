//
//  TestCasesModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import Foundation

struct TestEntity: Codable, Equatable {
    let id: Int
    let position: Int
    var title: String
    var description: String?
    var preconditions: String?
    var postconditions: String?
    var severity: Int
    var priority: Int
    var type: Int
    var layer: Int
    var isFlaky: Int
    var behavior: Int
    var automation: Int
    var status: Int
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
        case id, position, title, description, preconditions, postconditions, severity, priority, type, layer, steps, params, tags, links, attachments, behavior, automation, status
        case isFlaky = "is_flaky"
        case suiteId = "suite_id"
        case customFields = "custom_fields"
        case stepsType = "steps_type"
        case memberId = "member_id"
        case authorId = "author_id"
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
    
    static func == (lhs: TestEntity, rhs: TestEntity) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.position == rhs.position &&
        lhs.description == rhs.description &&
        lhs.preconditions == rhs.preconditions &&
        lhs.postconditions == rhs.postconditions &&
        lhs.severity == rhs.severity &&
        lhs.priority == rhs.priority &&
        lhs.type == rhs.type &&
        lhs.isFlaky == rhs.isFlaky &&
        lhs.behavior == rhs.behavior &&
        lhs.automation == rhs.automation &&
        lhs.suiteId == rhs.suiteId &&
        lhs.status == rhs.status &&
        lhs.links == rhs.links &&
        lhs.customFields == rhs.customFields &&
        lhs.attachments == rhs.attachments &&
        lhs.stepsType == rhs.stepsType &&
        lhs.params == rhs.params &&
        lhs.steps == rhs.steps &&
        lhs.memberId == rhs.memberId &&
        lhs.authorId == rhs.authorId &&
        lhs.tags == rhs.tags
    }
}

struct TestCasesModel: Codable {
    let status: Bool
    let result: TestResult
}

struct TestCaseModel: Codable {
    let status: Bool
    let result: TestEntity
}

struct TestResult: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [TestEntity]
}

struct StepsInTestCase: Codable, Equatable {
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

// MARK: - response models
struct UpdateResponseModel: Codable {
    let status: Bool
    let result: UpdatedTestCaseListModel
}

struct UpdatedTestCaseListModel: Codable {
    let id: Int
}
