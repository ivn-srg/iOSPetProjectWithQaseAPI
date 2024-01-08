//
//  Result.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import Foundation

struct Result: Codable {
    let total: Int
    let filtered: Int
    let count: Int
    let entities: [Entity]
}
