//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

let emptyText = "Not set"


struct MenuItem {
    var id: Int
    var title: String
    var image: UIImage? = nil
}

enum Severity: String, CaseIterable, MenuDataSource {
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
    
    static var dataSource = [
        MenuItem(id: 0, title: Severity.nothing.rawValue, image: AppTheme.minusImage),
        MenuItem(id: 1, title: Severity.blocker.rawValue, image: AppTheme.nosignImage),
        MenuItem(id: 2, title: Severity.critical.rawValue, image: AppTheme.chevronDoubleUpImage),
        MenuItem(id: 3, title: Severity.major.rawValue, image: AppTheme.chevronUpImage),
        MenuItem(id: 4, title: Severity.normal.rawValue, image: AppTheme.circleImage),
        MenuItem(id: 5, title: Severity.minor.rawValue, image: AppTheme.chevronDownImage),
        MenuItem(id: 6, title: Severity.trivial.rawValue, image: AppTheme.chevronDoubleDownImage),
    ]
}
    

enum Status: String, CaseIterable, MenuDataSource {
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
    
    static var dataSource = [
        MenuItem(id: 0, title: Status.actual.rawValue),
        MenuItem(id: 1, title: Status.draft.rawValue),
        MenuItem(id: 2, title: Status.deprecated.rawValue)
    ]
}

enum Priority: String, CaseIterable, MenuDataSource {
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
    
    static var dataSource = [
        MenuItem(id: 0, title: Priority.nothing.rawValue, image: AppTheme.minusImage),
        MenuItem(id: 1, title: Priority.high.rawValue, image: AppTheme.arrowUpImage),
        MenuItem(id: 2, title: Priority.medium.rawValue, image: AppTheme.circleImage),
        MenuItem(id: 3, title: Priority.low.rawValue, image: AppTheme.arrowDownImage)
    ]
}

enum Behavior: String, CaseIterable, MenuDataSource {
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
    
    static var dataSource = [
        MenuItem(id: 0, title: Behavior.nothing.rawValue),
        MenuItem(id: 1, title: Behavior.positive.rawValue),
        MenuItem(id: 2, title: Behavior.negative.rawValue),
        MenuItem(id: 3, title: Behavior.destructive.rawValue)
    ]
}

enum Types: String, CaseIterable, MenuDataSource {
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
    
    static var dataSource = [
        MenuItem(id: 0, title: Types.other.rawValue),
        MenuItem(id: 1, title: Types.functional.rawValue),
        MenuItem(id: 2, title: Types.smoke.rawValue),
        MenuItem(id: 3, title: Types.regression.rawValue),
        MenuItem(id: 4, title: Types.security.rawValue),
        MenuItem(id: 5, title: Types.utility.rawValue),
        MenuItem(id: 6, title: Types.perfomance.rawValue),
        MenuItem(id: 7, title: Types.accertance.rawValue),
        MenuItem(id: 7, title: Types.compatibility.rawValue),
        MenuItem(id: 8, title: Types.exploratory.rawValue),
        MenuItem(id: 9, title: Types.integration.rawValue),
    ]
}

enum Layer: String, CaseIterable, MenuDataSource {
    case e2e = "E2E"
    case api = "API"
    case unit = "Unit"
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Layer.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Layer.e2e.rawValue, image: AppTheme.computerImage),
        MenuItem(id: 1, title: Layer.api.rawValue, image: AppTheme.apiImage),
        MenuItem(id: 2, title: Layer.unit.rawValue, image: AppTheme.gearDoubleFillImage)
    ]
}

enum AutomationStatus: String, CaseIterable, MenuDataSource {
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
    static var dataSource = [
        MenuItem(id: 0, title: AutomationStatus.manual.rawValue, image: AppTheme.handRaisedImage),
        MenuItem(id: 1, title: AutomationStatus.toBeAutomated.rawValue, image: AppTheme.personWithGearshapeImage),
        MenuItem(id: 2, title: AutomationStatus.automation.rawValue, image: AppTheme.gearshapeImage)
    ]
}

enum PlaceOfRequest {
    case start, continuos, refresh
}

var TOKEN = ""

var PROJECT_NAME = ""

let apiManager = APIManager.shared
