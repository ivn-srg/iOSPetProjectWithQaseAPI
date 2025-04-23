//
//  SharedResponseModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.09.2024.
//

final class SharedResponseModel: Codable {
    let status: Bool
}

struct ServerResponseModel<T: Codable>: Codable {
    let status: FlexibleBool?
    let result: T
}

struct ResponseWithErrorModel: Codable {
    let status: Bool?
    let errorMessage: String?
    let message: String?
    let errors: [String: [String]]?
}

enum FlexibleBool: Codable {
    case bool(Bool)
    case int(Int)
    
    var value: Bool {
        switch self {
        case .bool(let boolValue):
            return boolValue
        case .int(let intValue):
            return intValue != 0
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            throw DecodingError.typeMismatch(
                FlexibleBool.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Bool or Int for FlexibleBool."
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .int(let intValue):
            try container.encode(intValue)
        }
    }
}
