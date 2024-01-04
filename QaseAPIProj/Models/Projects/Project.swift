//
//  Project.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 04.01.2024.
//

import Foundation

struct Project {
    let title: String
    let code: String
    let counts: [String:Any]
}

struct Count {
    let countOfCases: Int
    let countOfSuites: Int
}
