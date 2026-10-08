//
//  Screens.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02.04.2025.
//

import XCTest

protocol Screen {
    var app: XCUIApplication { get }
}

struct AuthScreen: Screen {
    let app: XCUIApplication

    func openProjects() -> ProjectsListScreen {
        let logoImage = app.images["logoImg"]
        XCTAssertTrue(logoImage.waitForExistence(timeout: 5))
        logoImage.press(forDuration: 2)

        let picker = app.buttons["project.picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()
        let manage = app.buttons["Manage projects"]
        XCTAssertTrue(manage.waitForExistence(timeout: 5))
        manage.tap()

        return ProjectsListScreen(app: app)
    }
}

struct ProjectsListScreen: Screen {
    let app: XCUIApplication
    
    private enum Identifiers {
        static let rbbButtonName = "addNewProjectRBB"
        static let navBar = "navigationBar"
    }

    func checkNavigationTitle() {
        let navBarTitle = app.navigationBars[Identifiers.navBar].staticTexts["Repository"]
        XCTAssertTrue(navBarTitle.waitForExistence(timeout: 5))
    }

    func openCreateProject() -> CreateProjectScreen {
        let addNewProjectRBB = app.buttons[Identifiers.rbbButtonName]
        XCTAssertTrue(addNewProjectRBB.waitForExistence(timeout: 5))
        addNewProjectRBB.tap()

        return CreateProjectScreen(app: app)
    }
}

struct CreateProjectScreen: Screen {
    let app: XCUIApplication

    func checkPresented() {
        XCTAssertTrue(app.staticTexts["Creating project"].waitForExistence(timeout: 5))
    }
}
