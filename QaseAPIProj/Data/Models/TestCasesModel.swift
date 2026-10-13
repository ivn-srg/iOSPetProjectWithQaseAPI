//
//  TestCasesModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import Foundation

struct TestCaseEntity: Codable, Equatable {
    let id: Int
    let position: Int
    var title: String
    var description, preconditions, postconditions: String?
    var severity: Severity
    var priority: Priority
    var type: Types
    var layer: Layer
    var behavior: Behavior
    var automation: AutomationStatus
    var status: Status
    var isFlaky: Bool
    var suiteId: Int?
    let links, customFields, attachments: [String]
    let stepsType: String?
    var steps: [StepsInTestCase]
    let params, tags: [String]
    let memberId, authorId: Int

    var dictOfValues: EncodableTestCase {
        EncodableTestCase(testCase: self)
    }

    static var empty: TestCaseEntity {
        return .init()
    }

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

        id = try container.decode(Int.self, forKey: .id)
        position = try container.decode(Int.self, forKey: .position)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        preconditions = try container.decodeIfPresent(String.self, forKey: .preconditions)
        postconditions = try container.decodeIfPresent(String.self, forKey: .postconditions)
        severity = try container.decode(Severity.self, forKey: .severity)
        priority = try container.decode(Priority.self, forKey: .priority)
        type = try container.decode(Types.self, forKey: .type)
        layer = try container.decode(Layer.self, forKey: .layer)

        let isFlakyInt = try container.decode(Int.self, forKey: .isFlaky)
        isFlaky = isFlakyInt == 1 ? true : false

        behavior = try container.decode(Behavior.self, forKey: .behavior)
        automation = try container.decode(AutomationStatus.self, forKey: .automation)
        status = try container.decode(Status.self, forKey: .status)
        suiteId = try container.decode(Int?.self, forKey: .suiteId)
        links = try container.decode([String].self, forKey: .links)
        customFields = try container.decode([String].self, forKey: .customFields)
        attachments = try container.decode([String].self, forKey: .attachments)
        stepsType = try container.decodeIfPresent(String.self, forKey: .stepsType)
        steps = try container.decode([StepsInTestCase].self, forKey: .steps)
        params = try container.decode([String].self, forKey: .params)
        memberId = try container.decode(Int.self, forKey: .memberId)
        authorId = try container.decode(Int.self, forKey: .authorId)
        tags = try container.decode([String].self, forKey: .tags)
    }

    static func == (lhs: TestCaseEntity, rhs: TestCaseEntity) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title == rhs.title && lhs.position == rhs.position &&
            lhs.description == rhs.description && lhs.preconditions == rhs.preconditions &&
            lhs.postconditions == rhs.postconditions &&
            lhs.severity == rhs.severity && lhs.priority == rhs.priority &&
            lhs.type == rhs.type && lhs.layer == rhs.layer && lhs.isFlaky == rhs.isFlaky &&
            lhs.behavior == rhs.behavior && lhs.automation == rhs.automation &&
            lhs.suiteId == rhs.suiteId && lhs.status == rhs.status &&
            lhs.links == rhs.links && lhs.customFields == rhs.customFields &&
            lhs.attachments == rhs.attachments && lhs.stepsType == rhs.stepsType &&
            lhs.params == rhs.params && lhs.steps == rhs.steps &&
            lhs.memberId == rhs.memberId && lhs.authorId == rhs.authorId &&
            lhs.tags == rhs.tags
    }
}

extension TestCaseEntity {
    init?(realmObject: TestEntityRO?) {
        guard let realmObject = realmObject else { return nil }

        id = realmObject.id
        position = realmObject.position
        title = realmObject.title
        description = realmObject.itemDescription
        preconditions = realmObject.preconditions
        postconditions = realmObject.postconditions
        severity = Severity(realmObject.severity)
        priority = Priority(realmObject.priority)
        type = Types(realmObject.type)
        layer = Layer(realmObject.layer)
        isFlaky = realmObject.isFlaky
        behavior = Behavior(realmObject.behavior)
        automation =  AutomationStatus(realmObject.automation)
        status = Status(realmObject.status)
        suiteId = realmObject.suiteId
        links = realmObject.links.toArray
        customFields = realmObject.customFields.toArray
        attachments = realmObject.attachments.toArray
        stepsType = realmObject.stepsType
        steps = realmObject.steps.map { StepsInTestCase(from: $0) }
        params = realmObject.params.toArray
        tags = realmObject.tags.toArray
        memberId = realmObject.memberId
        authorId = realmObject.authorId
    }

    init() {
        id = 0
        position = 0
        title = ""
        description = ""
        preconditions = ""
        postconditions = ""
        severity = .nothing
        priority = .nothing
        type = .other
        layer = .e2e
        isFlaky = false
        behavior = .positive
        automation = .manual
        status = .actual
        suiteId = nil
        links = []
        customFields = []
        attachments = []
        stepsType = ""
        steps = []
        params = []
        tags = []
        memberId = 0
        authorId = 0
    }
}

struct TestCasesModel: Codable {
    let status: Bool
    let result: TestResult
}

struct TestCaseModel: Codable {
    let status: Bool
    let result: TestCaseEntity
}

struct TestResult: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [TestCaseEntity]
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
    var steps: [StepsInTestCase]?

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
        sharedStepHash = try container.decodeIfPresent(String.self, forKey: .sharedStepHash)
        sharedStepNestedHash = try container.decodeIfPresent(String.self, forKey: .sharedStepNestedHash)
        attachments = try container.decode([Int].self, forKey: .attachments)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        expectedResult = try container.decodeIfPresent(String.self, forKey: .expectedResult)
        data = try container.decodeIfPresent(String.self, forKey: .data)
        steps = try container.decodeIfPresent([StepsInTestCase].self, forKey: .steps)
    }

    init(
        hash: String,
        position: Int,
        sharedStepHash: String?,
        sharedStepNestedHash: String?,
        attachments: [Int],
        action: String?,
        expectedResult: String?,
        data: String?,
        steps: [StepsInTestCase]
    ) {
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

    init(from realmObject: StepsInTestCaseRO) {
        self.hash = realmObject.originalHash ?? realmObject.entityHash
        self.position = realmObject.position
        self.sharedStepHash = realmObject.sharedStepHash
        self.sharedStepNestedHash = realmObject.sharedStepNestedHash
        self.attachments = Array(realmObject.attachments)
        self.action = realmObject.action
        self.expectedResult = realmObject.expectedResult
        self.data = realmObject.data
        self.steps = realmObject.steps.map { StepsInTestCase(from: $0) }
    }

    init() {
        self.init(
            hash: UUID().uuidString,
            position: 0,
            sharedStepHash: "",
            sharedStepNestedHash: "",
            attachments: [],
            action: "",
            expectedResult: "",
            data: "",
            steps: []
        )
    }

    init(action: String) {
        self.init(
            hash: UUID().uuidString,
            position: 0,
            sharedStepHash: "",
            sharedStepNestedHash: "",
            attachments: [],
            action: action,
            expectedResult: "",
            data: "",
            steps: [StepsInTestCase()]
        )
    }
}

extension StepsInTestCase: Hashable {}

// MARK: - response models
struct CreateOrUpdateTestCaseModel: Codable {
    let id: Int?
    let status: Bool?
}

struct EncodableTestCase: Encodable {
    var title: String
    var description, preconditions, postconditions: String?
    var severity, priority, type, layer: Int
    var behavior, automation, status: Int
    var isFlaky: Int
    var suiteId: Int?
    var attachments, tags: [String]
    var steps: [StepsInTestCase]?

    enum CodingKeys: String, CodingKey {
        case title, description, preconditions, postconditions,
             severity, priority, type, layer, behavior, automation, status,
             attachments, tags, steps
        case isFlaky = "is_flaky"
        case suiteId = "suite_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(severity, forKey: .severity)
        try container.encode(priority, forKey: .priority)
        try container.encode(type, forKey: .type)
        try container.encode(layer, forKey: .layer)
        try container.encode(behavior, forKey: .behavior)
        try container.encode(automation, forKey: .automation)
        try container.encode(status, forKey: .status)
        try container.encode(isFlaky, forKey: .isFlaky)
        try container.encode(suiteId, forKey: .suiteId)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(preconditions, forKey: .preconditions)
        try container.encodeIfPresent(postconditions, forKey: .postconditions)
        try container.encodeIfPresent(steps, forKey: .steps)
    }

    init(testCase: TestCaseEntity) {
        self.title = testCase.title
        self.description = testCase.description
        self.preconditions = testCase.preconditions
        self.postconditions = testCase.postconditions
        self.severity = testCase.severity.apiValue
        self.priority = testCase.priority.apiValue
        self.type = testCase.type.apiValue
        self.layer = testCase.layer.apiValue
        self.behavior = testCase.behavior.apiValue
        self.automation = testCase.automation.apiValue
        self.status = testCase.status.apiValue
        self.isFlaky = testCase.isFlaky ? 1 : 0
        self.suiteId = testCase.suiteId == 0 ? nil : testCase.suiteId
        self.attachments = testCase.attachments
        self.tags = testCase.tags
        self.steps = testCase.steps
    }
}
