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
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Severity.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Severity.nothing.localized, image: AppTheme.minusImage),
        MenuItem(id: 1, title: Severity.blocker.localized, image: AppTheme.nosignImage),
        MenuItem(id: 2, title: Severity.critical.localized, image: AppTheme.chevronDoubleUpImage),
        MenuItem(id: 3, title: Severity.major.localized, image: AppTheme.chevronUpImage),
        MenuItem(id: 4, title: Severity.normal.localized, image: AppTheme.circleImage),
        MenuItem(id: 5, title: Severity.minor.localized, image: AppTheme.chevronDownImage),
        MenuItem(id: 6, title: Severity.trivial.localized, image: AppTheme.chevronDoubleDownImage),
    ]
}
    

enum Status: String, CaseIterable, MenuDataSource {
    case actual = "Actual"
    case draft = "Draft"
    case deprecated = "Deprecated"
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Status.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Status.actual.localized),
        MenuItem(id: 1, title: Status.draft.localized),
        MenuItem(id: 2, title: Status.deprecated.localized)
    ]
}

enum Priority: String, CaseIterable, MenuDataSource {
    case nothing = "Not Set"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Priority.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Priority.nothing.localized, image: AppTheme.minusImage),
        MenuItem(id: 1, title: Priority.high.localized, image: AppTheme.arrowUpImage),
        MenuItem(id: 2, title: Priority.medium.localized, image: AppTheme.circleImage),
        MenuItem(id: 3, title: Priority.low.localized, image: AppTheme.arrowDownImage)
    ]
}

enum Behavior: String, CaseIterable, MenuDataSource {
    case nothing = "Not Set"
    case positive = "Positive"
    case negative = "Negative"
    case destructive = "Destructive"
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Behavior.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Behavior.nothing.localized),
        MenuItem(id: 1, title: Behavior.positive.localized),
        MenuItem(id: 2, title: Behavior.negative.localized),
        MenuItem(id: 3, title: Behavior.destructive.localized)
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
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Types.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Types.other.localized),
        MenuItem(id: 1, title: Types.functional.localized),
        MenuItem(id: 2, title: Types.smoke.localized),
        MenuItem(id: 3, title: Types.regression.localized),
        MenuItem(id: 4, title: Types.security.localized),
        MenuItem(id: 5, title: Types.utility.localized),
        MenuItem(id: 6, title: Types.perfomance.localized),
        MenuItem(id: 7, title: Types.accertance.localized),
        MenuItem(id: 7, title: Types.compatibility.localized),
        MenuItem(id: 8, title: Types.exploratory.localized),
        MenuItem(id: 9, title: Types.integration.localized),
    ]
}

enum Layer: String, CaseIterable, MenuDataSource {
    case e2e = "E2E"
    case api = "API"
    case unit = "Unit"
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in Layer.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Layer.e2e.localized, image: AppTheme.computerImage),
        MenuItem(id: 1, title: Layer.api.localized, image: AppTheme.apiImage),
        MenuItem(id: 2, title: Layer.unit.localized, image: AppTheme.gearDoubleFillImage)
    ]
}

enum AutomationStatus: String, CaseIterable, MenuDataSource {
    case manual = "Manual"
    case toBeAutomated = "To be automated"
    case automation = "Automated"
    
    var localized: String {
        self.rawValue.localized
    }
    
    static func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in AutomationStatus.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: AutomationStatus.manual.localized, image: AppTheme.handRaisedImage),
        MenuItem(id: 1, title: AutomationStatus.toBeAutomated.localized, image: AppTheme.personWithGearshapeImage),
        MenuItem(id: 2, title: AutomationStatus.automation.localized, image: AppTheme.gearshapeImage)
    ]
}

enum PlaceOfRequest {
    case start, continuos, refresh
}

var TOKEN = ""

var PROJECT_NAME = ""

let apiManager = APIManager.shared
