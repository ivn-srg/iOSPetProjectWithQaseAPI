//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

struct MenuItem {
    var id: Int
    var title: String
    var image: UIImage? = nil
    
    init(id: Int, title: String, image: UIImage? = nil) {
        self.id = id
        self.title = title
        self.image = image
    }
    
    init() {
        self.init(id: 0, title: "")
    }
}

enum PlaceOfRequest {
    case start, continuos, refresh
}

enum FieldType: String, CaseIterable {
    case title = "Title"
    case description = "Description"
    case precondition = "Precondition"
    case postcondition = "Postcondition"
    case code = "Project code"
    case parentSuite = "Parent suite"
    case severity = "Severity"
    case status = "Status"
    case priority = "Priority"
    case behavior = "Behavior"
    case type = "Type"
    case layer = "Layer"
    case isFlaky = "Is Flaky"
    case automation = "Automation status"
    
    var localized: String {
        self.rawValue.localized
    }
}

struct Constants {
    static let LIMIT_OF_REQUEST = 50
    static let EMPTY_TEXT = "Not set".localized
}

var PROJECT_NAME = ""

let apiManager = ApiServiceConfiguration.shared.apiService
