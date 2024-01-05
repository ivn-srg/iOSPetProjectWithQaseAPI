//
//  Counts.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import Foundation

struct Counts: Codable {
    let cases: Int
    let suites: Int
    let milestones: Int
    let runs: Runs
    let defects: Defects
}
