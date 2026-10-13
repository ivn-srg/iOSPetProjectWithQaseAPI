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
        let demo = app.buttons[AccessibilityID.authDemo.identifier]
        XCTAssertTrue(demo.waitForExistence(timeout: 5))
        if !demo.isHittable { app.swipeUp() }
        demo.tap()

        let picker = app.buttons[AccessibilityID.projectPicker.identifier]
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
        static let rbbButtonName = AccessibilityID.addNewProjectRBB.identifier
        static let navBar = AccessibilityID.navigationBar.identifier
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

struct EntityFormScreen: Screen {
    let app: XCUIApplication

    func selectCase() {
        let segment = app.segmentedControls[AccessibilityID.formEntityType.identifier]
        XCTAssertTrue(segment.waitForExistence(timeout: 5))
        segment.buttons.element(boundBy: 1).tap()
    }

    func enterTitle(_ value: String) {
        let field = app.textViews[AccessibilityID.field(.title).identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(value)
    }

    func openParentPicker() -> SuiteParentPickerScreen {
        let parent = app.buttons[AccessibilityID.field(.parentSuite).identifier]
        XCTAssertTrue(parent.waitForExistence(timeout: 5))
        if !parent.isHittable { app.swipeUp() }
        parent.tap()
        return SuiteParentPickerScreen(app: app)
    }

    func checkCreateEnabled(_ enabled: Bool) {
        let create = app.buttons[AccessibilityID.formCreate.identifier]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        XCTAssertEqual(create.isEnabled, enabled)
    }
}

struct SuiteParentPickerScreen: Screen {
    let app: XCUIApplication

    func chooseRoot() {
        let root = app.cells[AccessibilityID.suitePickerRoot.identifier]
        XCTAssertTrue(root.waitForExistence(timeout: 5))
        root.tap()
    }

    func cancel() {
        let close = app.buttons[AccessibilityID.suitePickerClose.identifier]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
    }
}
