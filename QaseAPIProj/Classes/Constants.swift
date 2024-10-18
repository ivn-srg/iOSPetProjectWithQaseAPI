//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

let emptyText = "Not set"

enum Severity: String, CaseIterable {
    case nothing = "Not set"
    case blocker = "Blocker"
    case critical = "Critical"
    case major = "Major"
    case normal = "Normal"
    case minor = "Minor"
    case trivial = "Trivial"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Severity.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

enum Status: String, CaseIterable {
    case actual = "Actual"
    case draft = "Draft"
    case deprecated = "Deprecated"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Status.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

enum Priority: String, CaseIterable {
    case nothing = "Not Set"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Priority.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

enum Behavior: String, CaseIterable {
    case nothing = "Not Set"
    case positive = "Positive"
    case negative = "Negative"
    case destructive = "Destructive"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Behavior.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

enum Types: String, CaseIterable {
    case other = "Other"
    case functional = "Functional"
    case smoke = "Smoke"
    case regression = "Regression"
    case security = "Security"
    case utility = "Utility"
    case perfomance = "Perfomance"
    case accertance = "Accertance"
    case compatibility = "Compatibility"
    case exploratory = "Exploratory"
    case integration = "Integration"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Types.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

enum Layer: String, CaseIterable {
    case e2e = "E2E"
    case api = "API"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Layer.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

enum AutomationStatus: String, CaseIterable {
    case manual = "Manual"
    case toBeAutomated = "To be automated"
    case automation = "Automated"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in AutomationStatus.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}

var TOKEN = ""

var PROJECT_NAME = ""

let apiManager = APIManager.shared
