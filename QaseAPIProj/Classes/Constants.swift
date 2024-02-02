//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

struct Constants {
    enum Severity: String {
        case nothing = "Not set"
        case blocker = "Blocker"
        case critical = "Critical"
        case major = "Major"
        case normal = "Normal"
        case minor = "Minor"
        case trivial = "Trivial"
    }
    
    enum Status: String {
        case actual = "Actual"
        case draft = "Draft"
        case deprecated = "Deprecated"
    }
    
    enum Priority: String {
        case nothing = "Not Set"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }
    
    enum Behavior: String {
        case nothing = "Not Set"
        case positive = "Positive"
        case negative = "Negative"
        case destructive = "Destructive"
    }
    
    enum `Type`: String {
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
    }
    
    enum Layer: String {
        case e2e = "E2E"
        case api = "API"
    }
    
    enum AutomationStatus: String {
        case manual = "Manual"
        case automation = "Automation"
    }
    
    enum APIType: String {
        case get = "GET"
        case post = "POST"
    }
    
    enum APIMethods: String {
        case project = "project"
        case suites = "suite"
        case cases = "case"
        case openedCase = ""
    }
    
    static var TOKEN = ""
    
    static let DOMEN = "https://api.qase.io/v1"
    
    static var urlString = {
        (APIMethod: APIMethods, codeOfProject: String?, limit: Int?, offset: Int?, caseId: Int?) -> String? in
        
        switch APIMethod {
        case .project:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            
            return "\(Constants.DOMEN)/project?limit=\(limit)&offset=\(offset)"
        case .suites:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            guard let codeOfProject = codeOfProject else { return nil }
            
            return "\(Constants.DOMEN)/suite/\(codeOfProject)?limit=\(limit)&offset=\(offset)"
        case .cases:
            guard let limit = limit else { return nil }
            guard let offset = offset else { return nil }
            guard let codeOfProject = codeOfProject else { return nil }
            
            return "\(Constants.DOMEN)/case/\(codeOfProject)/?limit=\(limit)&offset=\(offset)"
        case .openedCase:
            guard let codeOfProject = codeOfProject else { return nil }
            guard let caseId = caseId else { return nil }
            
            return "\(Constants.DOMEN)/case/\(codeOfProject)/\(caseId)"
        }
    }
}
