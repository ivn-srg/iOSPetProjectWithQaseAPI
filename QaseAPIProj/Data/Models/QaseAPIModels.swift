//
//  QaseAPIModels.swift
//  QaseAPIProj
//

import Foundation

struct QaseAPIResponse<Result: Codable>: Codable {
    let status: FlexibleBool?
    let result: Result?
}

struct QaseAPIListResult<Entity: Codable>: Codable {
    let total: Int?
    let filtered: Int?
    let count: Int?
    let entities: [Entity]
}

struct QaseAPIIDResult: Codable {
    let id: Int
}

struct QaseAPIProjectCodeResult: Codable {
    let code: String
}

struct QaseAPIIDsResult: Codable {
    let ids: [Int]
}

struct QaseAPIHashResult: Codable {
    let hash: String
}

struct QaseAPIEmptyResult: Codable {}

enum QaseAPIJSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case integer(Int)
    case number(Double)
    case string(String)
    case array([QaseAPIJSONValue])
    case object([String: QaseAPIJSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([QaseAPIJSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: QaseAPIJSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

enum QaseAPIIdentifier: Codable, Equatable {
    case integer(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .integer(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

struct QaseAPIObjectRequest: Codable {
    let values: [String: QaseAPIJSONValue]

    init(values: [String: QaseAPIJSONValue]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        values = try decoder.singleValueContainer().decode([String: QaseAPIJSONValue].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: QaseAPIAnyCodingKey.self)
        for (key, value) in values {
            try container.encode(value, forKey: QaseAPIAnyCodingKey(stringValue: key)!)
        }
    }
}

private struct QaseAPIAnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

enum QaseAPIProjectAccess: String, Codable {
    case all, group, none
}

struct QaseAPIProjectCreateRequest: Codable {
    let title: String
    let code: String
    var description: String?
    var access: QaseAPIProjectAccess?
    var group: String?
    var settings: QaseAPIJSONValue?
}

struct QaseAPISuiteCreateRequest: Codable {
    let title: String
    var description: String?
    var preconditions: String?
    var parentId: Int?
}

struct QaseAPISuiteUpdateRequest: Codable {
    var title: String?
    var description: String?
    var preconditions: String?
    var parentId: Int?
}

struct QaseAPIBulkCasesRequest: Codable {
    let cases: [QaseAPIObjectRequest]
}

struct QaseAPIExternalIssueRequest: Codable {
    let type: String
    let links: [QaseAPIObjectRequest]
}

struct QaseAPIConfigurationGroupRequest: Codable {
    let title: String
    let configurations: [String]?
}

struct QaseAPIConfigurationRequest: Codable {
    let title: String
    let groupId: Int
}

struct QaseAPICustomFieldCreateRequest: Codable {
    let title: String
    let entity: Int
    let type: Int
    var value: [QaseAPICustomFieldOption]?
    var placeholder: String?
    var defaultValue: String?
    var isFilterable: Bool?
    var isVisible: Bool?
    var isRequired: Bool?
    var isEnabledForAllProjects: Bool?
    var projectsCodes: [String]?
}

struct QaseAPICustomFieldUpdateRequest: Codable {
    var title: String?
    var entity: Int?
    var type: Int?
    var value: [QaseAPICustomFieldOption]?
    var placeholder: String?
    var defaultValue: String?
    var isFilterable: Bool?
    var isVisible: Bool?
    var isRequired: Bool?
    var isEnabledForAllProjects: Bool?
    var projectsCodes: [String]?
}

struct QaseAPICustomFieldOption: Codable {
    let title: String
    let value: String?
}

struct QaseAPIDefectCreateRequest: Codable {
    let title: String
    let actualResult: String
    let severity: Int
    var milestoneId: Int?
    var attachments: [String]?
    var customField: [String: String]?
    var tags: [String]?
}

struct QaseAPIDefectUpdateRequest: Codable {
    var title: String?
    var actualResult: String?
    var severity: Int?
    var milestoneId: Int?
    var attachments: [String]?
    var customField: [String: String]?
    var tags: [String]?
}

struct QaseAPIDefectStatusRequest: Codable {
    let status: String
}

struct QaseAPIEnvironmentCreateRequest: Codable {
    let title: String
    let slug: String
}

struct QaseAPIEnvironmentUpdateRequest: Codable {
    var title: String?
    var slug: String?
}

enum QaseAPIMilestoneStatus: String, Codable {
    case active, completed
}

struct QaseAPIMilestoneCreateRequest: Codable {
    let title: String
    var description: String?
    var dueDate: String?
    var status: QaseAPIMilestoneStatus?
}

struct QaseAPIMilestoneUpdateRequest: Codable {
    var title: String?
    var description: String?
    var status: QaseAPIMilestoneStatus?
}

struct QaseAPIPlanCreateRequest: Codable {
    let title: String
    var description: String?
    let cases: [Int]
}

struct QaseAPIPlanUpdateRequest: Codable {
    var title: String?
    var description: String?
    var cases: [Int]?
}

struct QaseAPIProjectAccessRequest: Codable {
    let memberId: Int
}

struct QaseAPIResultCreateRequest: Codable {
    var caseId: Int?
    var caseObject: QaseAPIJSONValue?
    let status: String
    var startTime: Int?
    var time: Int?
    var timeMs: Int?
    var defect: Bool?
    var attachments: [String]?
    var stacktrace: String?
    var comment: String?
    var steps: [QaseAPIObjectRequest]?
    var param: [String: String]?
    var paramGroups: [[String]]?
    var authorId: Int?

    enum CodingKeys: String, CodingKey {
        case caseId, status, startTime, time, timeMs, defect, attachments, stacktrace, comment, steps, param,
             authorId
        case caseObject = "case"
        case paramGroups = "param_groups"
    }
}

struct QaseAPIResultUpdateRequest: Codable {
    var status: String?
    var timeMs: Int?
    var defect: Bool?
    var attachments: [String]?
    var stacktrace: String?
    var comment: String?
    var steps: [QaseAPIObjectRequest]?
}

struct QaseAPIResultBulkRequest: Codable {
    let results: [QaseAPIResultCreateRequest]
}

struct QaseAPIReviewRequest: Codable {
    var title: String?
    var description: String?
    var cases: [Int]?
    var status: String?
}

struct QaseAPIReviewBulkRequest: Codable {
    let reviews: [QaseAPIReviewRequest]
}

struct QaseAPIRunCreateRequest: Codable {
    let title: String
    var description: String?
    var includeAllCases: Bool?
    var cases: [Int]?
    var isAutotest: Bool?
    var environmentId: Int?
    var environmentSlug: String?
    var milestoneId: Int?
    var planId: Int?
    var authorId: Int?
    var tags: [String]?
    var configurations: [Int]?
    var customField: [String: String]?
    var startTime: String?
    var endTime: String?
    var isCloud: Bool?
    var cloudRunConfig: QaseAPIJSONValue?
}

struct QaseAPIRunUpdateRequest: Codable {
    var title: String?
    var description: String?
    var environmentId: Int?
    var environmentSlug: String?
    var milestoneId: Int?
    var tags: [String]?
    var configurations: [Int]?
    var customField: [String: String]?
}

struct QaseAPIRunExternalIssueRequest: Codable {
    let type: String
    let links: [QaseAPIObjectRequest]
}

struct QaseAPIRunPublicRequest: Codable {
    let status: Bool
}

enum QaseAPISharedParameterType: String, Codable {
    case single, group
}

struct QaseAPISharedParameterCreateRequest: Codable {
    let title: String
    let type: QaseAPISharedParameterType
    var projectCodes: [String]?
    let isEnabledForAllProjects: Bool
    let parameters: [QaseAPIJSONValue]

    init?(
        title: String,
        type: QaseAPISharedParameterType,
        projectCodes: [String]?,
        isEnabledForAllProjects: Bool,
        parameters: [QaseAPIJSONValue]
    ) {
        guard !parameters.isEmpty else { return nil }
        self.title = title
        self.type = type
        self.projectCodes = projectCodes
        self.isEnabledForAllProjects = isEnabledForAllProjects
        self.parameters = parameters
    }
}

struct QaseAPISharedParameterUpdateRequest: Codable {
    var title: String?
    var projectCodes: [String]?
    var isEnabledForAllProjects: Bool?
    var parameters: [QaseAPIJSONValue]?
}

struct QaseAPISharedStepCreateRequest: Codable {
    let title: String
    var description: String?
    var steps: [QaseAPIObjectRequest]?
}

struct QaseAPISharedStepUpdateRequest: Codable {
    var title: String?
    var description: String?
    var steps: [QaseAPIObjectRequest]?
}

struct QaseAPIAttachmentDTO: Codable {
    let hash: String?
    let filename: String?
    let mime: String?
    let size: Int?
    let url: String?
}

struct QaseAPIAuthorDTO: Codable {
    let id: Int?
    let name: String?
    let email: String?
    let type: String?
}

struct QaseAPIUserDTO: Codable {
    let id: Int?
    let name: String?
    let email: String?
    let title: String?
    let status: Int?
}

struct QaseAPIResourceDTO: Codable {
    let id: QaseAPIIdentifier?
    let code: String?
    let title: String?
    let description: String?
    let status: QaseAPIJSONValue?
    let type: QaseAPIJSONValue?
    let slug: String?
    let hash: String?
    let fields: [String: QaseAPIJSONValue]?

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case id, code, title, description, status, type, slug, hash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(QaseAPIIdentifier.self, forKey: .id)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decodeIfPresent(QaseAPIJSONValue.self, forKey: .status)
        type = try container.decodeIfPresent(QaseAPIJSONValue.self, forKey: .type)
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        hash = try container.decodeIfPresent(String.self, forKey: .hash)

        let dynamicContainer = try decoder.container(keyedBy: QaseAPIAnyCodingKey.self)
        var additionalFields = [String: QaseAPIJSONValue]()
        for key in dynamicContainer.allKeys where CodingKeys(stringValue: key.stringValue) == nil {
            additionalFields[key.stringValue] = try dynamicContainer.decode(
                QaseAPIJSONValue.self,
                forKey: key
            )
        }
        fields = additionalFields.isEmpty ? nil : additionalFields
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(hash, forKey: .hash)

        var dynamicContainer = encoder.container(keyedBy: QaseAPIAnyCodingKey.self)
        for (key, value) in fields ?? [:] {
            try dynamicContainer.encode(value, forKey: QaseAPIAnyCodingKey(stringValue: key)!)
        }
    }
}
