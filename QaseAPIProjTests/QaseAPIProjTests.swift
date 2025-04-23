//
//  QaseAPIProjTests.swift
//  QaseAPIProjTests
//
//  Created by Sergey Ivanov on 01.04.2025.
//

import Testing
import UIKit
@testable import QaseAPIProj

struct QaseAPIProjTests {
    
    let apiManager = APIMockManager.shared
    
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let whiteColor = UIColor.white
        let blackColor = UIColor.black
        
        #expect(whiteColor.toHex() == "#FFFFFF")
        #expect(blackColor.toHex() == "#000000")
        
        #expect(UIColor(hex: "#0000FF") == .blue)
        #expect(UIColor(hex: "#996633") == .brown)
    }
    
    @Test("API compose method checking")
    func checkValidURL() async throws {
        let projectUrl = apiManager.composeURL(for: .project, urlComponents: nil, queryItems: [.limit: 10])!
        
        #expect(projectUrl.absoluteString == "https://api.qase.io/v1/project?limit=10")
    }
    
    @Test func checkFirstProjectTitle() async throws {
        let dataURL = apiManager.composeURL(for: .project, urlComponents: nil)!
        let projectsData = try await apiManager.performRequest(from: dataURL, method: .get, modelType: ProjectDataModel.self)
        let projects = projectsData.result.entities
        
        #expect(projects.count == 2)
        #expect(projects[0].title == "Demo Project")
        #expect(projects[1].title == "1Forma")
    }
}
