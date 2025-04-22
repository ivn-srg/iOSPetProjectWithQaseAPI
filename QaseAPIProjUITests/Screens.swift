//
//  Screens.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02.04.2025.
//

import XCTest
import Foundation

protocol Screen {
    var app: XCUIApplication { get }
}

struct AuthScreen: Screen {
    let app: XCUIApplication
    
    private enum Identifiers {
        static let imageViewName = "logoImg"
        static let textFieldName = "inputTextField"
        static let buttonName = "authButton"
    }
    
    private lazy var logoImage = {
        app.images[Identifiers.imageViewName]
    }()
    
    private lazy var inputTextField = {
        app.textFields[Identifiers.textFieldName]
    }()
    
    private lazy var nextButton = {
        app.buttons[Identifiers.buttonName]
    }()
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    mutating func fallingIntoProjectsScreen() -> ProjectsListScreen {
        logoImage.press(forDuration: 2)
        
        return ProjectsListScreen(app: app)
    }
}

struct ProjectsListScreen: Screen {
    let app: XCUIApplication
    
    private enum Identifiers {
        static let rbbButtonName = "addNewProjectRBB"
        static let tableViewName = "projectsTableView"
        static let navBar = "navigationBar"
    }
    
    private lazy var projectsTableView = {
        app.tables[Identifiers.tableViewName]
    }()
    
    private lazy var projectsTableViewCell = {
        projectsTableView.cells.firstMatch
    }()
    
    private lazy var addNewProjectRBB = {
        app.buttons[Identifiers.rbbButtonName]
    }()
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func checkNavigationTitle() {
        sleep(3)
        
        let navBarTitle = app.navigationBars[Identifiers.navBar].staticTexts["Repository"]
        XCTAssertTrue(navBarTitle.exists)
    }
    
    mutating func tapOnRightBarButton() -> CreateProjectScreen {
        sleep(3)
        
        addNewProjectRBB.tap()
        
        return CreateProjectScreen(app: app)
    }
}

struct CreateProjectScreen: Screen {
    let app: XCUIApplication
    
    private enum Identifiers {
    }
}
