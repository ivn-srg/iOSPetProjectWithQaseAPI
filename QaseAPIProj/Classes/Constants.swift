//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

struct Constants {
    static let emptyText = "Not set"
    
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
    
    enum APIType: String {
        case get = "GET"
        case post = "POST"
    }
    
    enum APIMethods: String, CaseIterable {
        case project = "project"
        case suites, suitesWithoutParent = "suite"
        case cases, casesWithoutParent = "case"
        case openedCase = ""
        
        func returnAllEnumCases() -> [String] {
            var listOfCases = [String]()
            
            for caseValue in APIMethods.allCases {
                listOfCases.append(caseValue.rawValue)
            }
            
            return listOfCases
        }
    }
    
    static var TOKEN = ""
    
    static let DOMEN = "https://api.qase.io/v1"
    
    static var PROJECT_NAME = ""
    
    static var urlString = {
        (APIMethod: APIMethods, codeOfProject: String?, limit: Int?, offset: Int?, parentSuite: ParentSuite?, caseId: Int?) -> String? in
        
        switch APIMethod {
        case .project:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            
            return "\(Constants.DOMEN)/project?limit=\(limit)&offset=\(offset)"
        case .suites:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            guard let codeOfProject = codeOfProject else { return nil }
            guard let parentSuite = parentSuite else { return nil }
            guard let searchSuiteString = parentSuite.title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }
            
            return "\(Constants.DOMEN)/suite/\(codeOfProject)?search=\"\(searchSuiteString)\"&limit=\(limit)&offset=\(offset)"
        case .cases:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            guard let codeOfProject = codeOfProject else { return nil }
            guard let parentSuite = parentSuite else { return nil }
            
            return "\(Constants.DOMEN)/case/\(codeOfProject)?suite_id=\(parentSuite.id)&limit=\(limit)&offset=\(offset)"
        case .suitesWithoutParent:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            guard let codeOfProject = codeOfProject else { return nil }
            
            return "\(Constants.DOMEN)/suite/\(codeOfProject)?limit=\(limit)&offset=\(offset)"
        case .casesWithoutParent:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            guard let codeOfProject = codeOfProject else { return nil }
            
            return "\(Constants.DOMEN)/case/\(codeOfProject)?limit=\(limit)&offset=\(offset)"
        case .openedCase:
            guard let codeOfProject = codeOfProject else { return nil }
            guard let caseId = caseId else { return nil }
            
            return "\(Constants.DOMEN)/case/\(codeOfProject)/\(caseId)"
        }
    }
}
