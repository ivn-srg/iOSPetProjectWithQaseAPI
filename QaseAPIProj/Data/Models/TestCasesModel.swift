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
    var description, preconditions, postconditions: String?
    var severity, priority, type, layer, isFlaky: Int
    var behavior, automation, status: Int
    let suiteId: Int?
    let links, customFields, attachments: [String]
    let stepsType: String?
    let steps: [StepsInTestCase]
    let params, tags: [String]
    let memberId, authorId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, position, title, description, preconditions, postconditions,
             severity, priority, type, layer, steps, params, tags, links,
             attachments, behavior, automation, status
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
        lhs.title == rhs.title && lhs.position == rhs.position &&
        lhs.description == rhs.description && lhs.preconditions == rhs.preconditions &&
        lhs.postconditions == rhs.postconditions &&
        lhs.severity == rhs.severity && lhs.priority == rhs.priority &&
        lhs.type == rhs.type && lhs.isFlaky == rhs.isFlaky &&
        lhs.behavior == rhs.behavior && lhs.automation == rhs.automation &&
        lhs.suiteId == rhs.suiteId && lhs.status == rhs.status &&
        lhs.links == rhs.links && lhs.customFields == rhs.customFields &&
        lhs.attachments == rhs.attachments && lhs.stepsType == rhs.stepsType &&
        lhs.params == rhs.params && lhs.steps == rhs.steps &&
        lhs.memberId == rhs.memberId && lhs.authorId == rhs.authorId &&
        lhs.tags == rhs.tags
    }
}

extension TestEntity {
    init?(realmObject: TestEntityRO?) {
        guard let realmObject = realmObject else { return nil }
        
        id = realmObject.id
        position = realmObject.position
        title = realmObject.title
        description = realmObject.itemDescription
        preconditions = realmObject.preconditions
        postconditions = realmObject.postconditions
        severity = realmObject.severity
        priority = realmObject.priority
        type = realmObject.type
        layer = realmObject.layer
        isFlaky = realmObject.isFlaky
        behavior = realmObject.behavior
        automation = realmObject.automation
        status = realmObject.status
        suiteId = realmObject.suiteId
        links = realmObject.links.toArray
        customFields = realmObject.customFields.toArray
        attachments = realmObject.attachments.toArray
        stepsType = realmObject.stepsType
        steps = realmObject.steps.toArray.map { StepsInTestCase(realmObject: $0) }
        params = realmObject.params.toArray
        tags = realmObject.tags.toArray
        memberId = realmObject.memberId
        authorId = realmObject.authorId
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
    let sharedStepHash: String?
    let sharedStepNestedHash: String?
    let attachments: [Int]
    let action: String?
    let expectedResult: String?
    let data: String?
    let steps: [StepsInTestCase]
    
    enum CodingKeys: String, CodingKey {
        case hash, position, attachments, action, data, steps
        case sharedStepHash = "shared_step_hash"
        case sharedStepNestedHash = "shared_step_nested_hash"
        case expectedResult = "expected_result"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        hash = try container.decode(String.self, forKey: .hash)
        position = try container.decode(Int.self, forKey: .position)
        sharedStepHash = try container.decode(String?.self, forKey: .sharedStepHash)
        sharedStepNestedHash = try container.decode(String?.self, forKey: .sharedStepNestedHash)
        attachments = try container.decode([Int].self, forKey: .attachments)
        action = try container.decode(String?.self, forKey: .action)
        expectedResult = try container.decode(String?.self, forKey: .expectedResult)
        data = try container.decode(String?.self, forKey: .data)
        steps = try container.decode([StepsInTestCase].self, forKey: .steps)
    }
    
    init(hash: String,position: Int, sharedStepHash: String?, sharedStepNestedHash: String?,
         attachments: [Int], action: String?, expectedResult: String?, data: String?, steps: [StepsInTestCase]) {
        self.hash = hash
        self.position = position
        self.sharedStepHash = sharedStepHash
        self.sharedStepNestedHash = sharedStepNestedHash
        self.attachments = attachments
        self.action = action
        self.expectedResult = expectedResult
        self.data = data
        self.steps = steps
    }
    
    init(realmObject: StepsInTestCaseRO) {
        self.hash = realmObject.testCaseHash
        self.position = realmObject.position
        self.sharedStepHash = realmObject.sharedStepHash
        self.sharedStepNestedHash = realmObject.sharedStepNestedHash
        self.action = realmObject.action
        self.expectedResult = realmObject.expectedResult
        self.data = realmObject.data
        self.attachments = realmObject.attachments.toArray
        self.steps = realmObject.steps.toArray.map { StepsInTestCase(action: $0)}
    }
    
    init() {
        self.init(hash: UUID().uuidString, position: 0, sharedStepHash: "", sharedStepNestedHash: "", attachments: [],
                  action: "", expectedResult: "", data: "", steps: [])
    }
    
    init(action: String) {
        self.init(hash: UUID().uuidString, position: 0, sharedStepHash: "", sharedStepNestedHash: "", attachments: [],
                  action: action, expectedResult: "", data: "", steps: [StepsInTestCase()])
    }
}

// MARK: - response models
struct CreateOrUpdateTestCaseModel: Codable {
    let id: Int
}

// MARK: - Create test case model
struct CreatingTestCase: Codable {
    var title: String
    var description, precondition, postcondition: String
    var severity, priority, type, layer: Int
    var isFlaky, behavior, automation, status: Int
    var suiteId: Int?
    var attachment, tags: [String]?
    var steps: StepsInTestCase?
    
    static var empty: CreatingTestCase {
        return .init(
            title: "",
            description: "", precondition: "",
            postcondition: "", severity: 0,
            priority: 0, type: 0,
            layer: 0, isFlaky: 0,
            behavior: 0, automation: 0,
            status: 0
        )
    }
}

