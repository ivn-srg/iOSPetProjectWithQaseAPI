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
        case suite = "suite"
        case cases = "case"
    }
    
    static var TOKEN = ""
    
    static var urlString = {
        (requiredEssence: String, codeOfProject: String?, limit: Int, offset: Int) -> String in
        
        if let codeOfProject = codeOfProject {
            return "https://api.qase.io/v1/\(requiredEssence)/\(codeOfProject)?limit=\(limit)&offset=\(offset)"
        } else {
            return "https://api.qase.io/v1/\(requiredEssence)?limit=\(limit)&offset=\(offset)"
        }
    }
}
