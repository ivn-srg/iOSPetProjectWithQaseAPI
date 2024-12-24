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
    let itemDescription: String?
    let preconditions: String?
    let position: Int
    let casesCount: Int
    let parentId: Int?
    
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
        itemDescription = try container.decode(String?.self, forKey: .itemDescription)
        preconditions = try container.decode(String?.self, forKey: .preconditions)
        position = try container.decode(Int.self, forKey: .position)
        casesCount = try container.decode(Int.self, forKey: .caseCount)
        parentId = try container.decode(Int?.self, forKey: .parentId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(itemDescription, forKey: .itemDescription)
        try container.encode(preconditions, forKey: .preconditions)
        try container.encode(position, forKey: .position)
        try container.encode(casesCount, forKey: .caseCount)
        try container.encode(parentId, forKey: .parentId)
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

struct CreatingSuite: Encodable {
    var title: String
    var description: String
    var preconditions: String
    var parentId: Int
    
    static var empty: CreatingSuite {
        return .init(title: "", description: "", preconditions: "", parentId: 0)
    }
}

struct CreateOrUpdateSuiteModel: Codable {
    let id: Int
}
