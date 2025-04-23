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
    let id: Int?
    var title: String
    var itemDescription: String?
    var preconditions: String?
    let position: Int?
    let casesCount: Int?
    var parentId: Int?
    
    static var empty: SuiteEntity {
        return .init(title: "", itemDescription: "", preconditions: "", parentId: 0)
    }
    
    init(title: String, itemDescription: String, preconditions: String, parentId: Int) {
        self.title = title
        self.itemDescription = itemDescription
        self.preconditions = preconditions
        self.parentId = parentId
        self.id = nil
        self.casesCount = nil
        self.position = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, position, preconditions
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
        position = try container.decode(Int.self, forKey: .position)
        casesCount = try container.decodeIfPresent(Int.self, forKey: .caseCount)
        parentId = try container.decodeIfPresent(Int.self, forKey: .parentId)
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
