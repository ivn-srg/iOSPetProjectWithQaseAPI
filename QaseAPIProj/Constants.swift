//
//  Constants.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 12.01.2024.
//

import UIKit

struct Constants {
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
