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
    let status: Bool
    let result: T
}
