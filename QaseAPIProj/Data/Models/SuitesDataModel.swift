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
    let entities: [TestListEntity]
}

struct TestListEntity: Codable {
    let isSuite: Bool
    let id: Int
    var title: String
    var itemDescription: String?
    var parentId: Int?

    // if isSuite
    var preconditions: String?
    let position: Int?
    let casesCount: Int?

    // if !isSuite
    let priority: Priority?
    let automation: AutomationStatus?

    var uniqueKey: String {
        "\(id)_\(isSuite)"
    }

    static var empty: TestListEntity {
        return .init(title: "", itemDescription: "", preconditions: "", parentId: 0)
    }

    init(
        isSuite: Bool, id: Int,
        title: String,  description: String?, parentId: Int?,
        casesCount: Int?, priority: Priority? = nil,
        automation: AutomationStatus? = nil
    ) {
        self.isSuite = isSuite
        self.id = id
        self.title = title
        self.itemDescription = description
        self.parentId = parentId
        self.casesCount = casesCount
        self.priority = priority
        self.automation = automation
        self.position = nil
    }

    init(suiteRO: TestEntitiesDataRO) {
        self.init(
            isSuite: suiteRO.isSuites,
            id: suiteRO.id,
            title: suiteRO.title,
            description: suiteRO.itemDescription,
            parentId: suiteRO.parentId,
            casesCount: suiteRO.casesCount,
            priority: suiteRO.priority.map(Priority.init),
            automation: suiteRO.automation.map(AutomationStatus.init)
        )
    }

    init(testCase: TestCaseEntity) {
        self.init(
            isSuite: false,
            id: testCase.id,
            title: testCase.title,
            description: testCase.description,
            parentId: testCase.suiteId,
            casesCount: nil,
            priority: testCase.priority,
            automation: testCase.automation
        )
    }

    init(title: String, itemDescription: String, preconditions: String, parentId: Int) {
        isSuite = true
        self.title = title
        self.itemDescription = itemDescription
        self.preconditions = preconditions
        self.parentId = parentId
        id = -1
        casesCount = nil
        position = nil
        priority = nil
        automation = nil
    }

    enum CodingKeys: String, CodingKey {
        case id, title, position, preconditions
        case priority, automation
        case parentId = "parent_id"
        case caseCount = "cases_count"
        case itemDescription = "description"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Раскодируйте каждое свойство
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        itemDescription = try container.decodeIfPresent(String.self, forKey: .itemDescription)
        preconditions = try container.decodeIfPresent(String.self, forKey: .preconditions)
        position = try container.decodeIfPresent(Int.self, forKey: .position)
        casesCount = try container.decodeIfPresent(Int.self, forKey: .caseCount)
        parentId = try container.decodeIfPresent(Int.self, forKey: .parentId)

        isSuite = true
        priority = nil
        automation = nil

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(itemDescription, forKey: .itemDescription)
        try container.encode(preconditions, forKey: .preconditions)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encodeIfPresent(casesCount, forKey: .caseCount)
        try container.encodeIfPresent(parentId, forKey: .parentId)
    }
}

struct ParentSuite {
    let id: Int
    let title: String
    let codeOfProject: String

    init?(id: Int?, title: String, codeOfProject: String) {
        guard let id else { return nil }

        self.id = id
        self.title = title
        self.codeOfProject = codeOfProject
    }
}

struct CreateOrUpdateSuiteModel: Codable {
    let id: Int
}
