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

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let whiteColor = UIColor.white
        let blackColor = UIColor.black
        
        #expect(whiteColor.toHex() == "#FFFFFF")
        #expect(blackColor.toHex() == "#000000")
        
        #expect(UIColor(hex: "#0000FF") == .blue)
        #expect(UIColor(hex: "#996633") == .brown)
    }

    @Test func checkFirstProjectTitle() async throws {
        let jsonFileUrl = Bundle.main.url(forResource: "project_data", withExtension: "json")
        let jsonData = try Data(contentsOf: jsonFileUrl!)
        let projectsModel = try! JSONDecoder().decode(ProjectDataModel.self, from: jsonData)
        let projects = projectsModel.result.entities
        
        #expect(projects.count == 2)
        #expect(projects[0].title == "Demo Project")
        #expect(projects[1].title == "1Forma")
    }
}
