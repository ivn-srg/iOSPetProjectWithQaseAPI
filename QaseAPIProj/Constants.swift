//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

struct Constants {
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
    
    static let notAutomationImage = UIImage(systemName: "hand.raised")?.withTintColor(.systemGray)
    static let toBeAutomationImage = UIImage(systemName: "person.2.badge.gearshape")?.withTintColor(.systemGray)
    static let automationImage = UIImage(systemName: "gearshape.fill")?.withTintColor(.systemGray)
    static let highPriorityImage = UIImage(systemName: "arrow.up")?.withTintColor(.red)
    static let mediumPriorityImage = UIImage(systemName: "circle")?.withTintColor(.systemGray)
    static let lowPriorityImage = UIImage(systemName: "arrow.down")?.withTintColor(.green)
}
