import XCTest

final class HomeScreenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITests", "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        let demo = app.buttons[AccessibilityID.authDemo.identifier]
        XCTAssertTrue(demo.waitForExistence(timeout: 5))
        demo.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].waitForExistence(timeout: 12))
        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "Demo Project"),
            object: app.buttons[AccessibilityID.projectPicker.identifier]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 12), .completed)
    }

    override func tearDownWithError() throws { app.terminate() }

    private func selectTab(_ identifier: AccessibilityID, title: String) {
        let identified = app.tabBars.buttons[identifier.identifier]
        let button = identified.exists ? identified : app.tabBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 5), app.debugDescription)
        button.tap()
    }

    private func reveal(_ identifier: AccessibilityID) -> XCUIElement {
        let item = app.descendants(matching: .any).matching(identifier: identifier.identifier).firstMatch
        for _ in 0 ..< 8 {
            if item.exists && item.isHittable { return item }
            app.swipeUp()
        }
        XCTAssertTrue(item.exists && item.isHittable, app.debugDescription)
        return item
    }

    func testProjectChoiceIsSharedAcrossTabs() {
        app.buttons[AccessibilityID.projectPicker.identifier].tap()
        let choice = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@",
            "1Forma"
        )).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].label.contains("1Forma"))
        selectTab(.tabRepository, title: "Репозиторий")
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].label.contains("1Forma"))
        selectTab(.tabWork, title: "Работа")
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].label.contains("1Forma"))
    }

    func testCaseOpenAddsRecentEntryAndSearchWorks() {
        app.buttons[AccessibilityID.homeAllCases.identifier].tap()
        let row = reveal(.repositoryCase(81))
        row.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 8))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        selectTab(.tabHome, title: "Главная")
        XCTAssertTrue(app.buttons[AccessibilityID.recent(project: "DEMO", caseID: 81).identifier]
            .waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Home light recent"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons[AccessibilityID.homeSearchCases.identifier].tap()
        let field = app.textFields[AccessibilityID.repositorySearch.identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Кейс верхнего")
        _ = reveal(.repositoryCase(81))
    }

    func testLargeTextLayout() {
        app.terminate()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        reveal(.authDemo).tap()
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Home accessibility"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let cases = app.buttons[AccessibilityID.homeAllCases.identifier]
        for _ in 0 ..< 6 where !cases.isHittable { app.swipeUp() }
        XCTAssertTrue(cases.isHittable)
        cases.tap()
        _ = reveal(.repositoryCase(81))
    }

    func testHierarchyAndBreadcrumbs() {
        app.buttons[AccessibilityID.homeAllCases.identifier].tap()
        let suite = app.buttons[AccessibilityID.repositorySuite(81).identifier]
        XCTAssertTrue(suite.waitForExistence(timeout: 8))
        suite.tap()
        let child = app.buttons[AccessibilityID.repositorySuite(82).identifier]
        XCTAssertTrue(child.waitForExistence(timeout: 8))
        child.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.repositorySuite(86).identifier]
            .waitForExistence(timeout: 8))
        app.buttons[AccessibilityID.breadcrumb(nil).identifier].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.repositorySuite(81).identifier]
            .waitForExistence(timeout: 8))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Repository root"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testDraftSurvivesCancelledTabAndBackNavigation() {
        app.buttons[AccessibilityID.homeAllCases.identifier].tap()
        let row = reveal(.repositoryCase(81))
        row.tap()
        let title = app.textViews[AccessibilityID.field(.title).identifier]
        XCTAssertTrue(title.waitForExistence(timeout: 8))
        title.tap()
        title.typeText(" Edited")
        app.navigationBars.buttons[AccessibilityID.formBack.identifier].tap()
        let stay = app.alerts.buttons["Продолжить редактирование"]
        XCTAssertTrue(stay.waitForExistence(timeout: 5))
        stay.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 5))
        selectTab(.tabHome, title: "Главная")
        XCTAssertTrue(stay.waitForExistence(timeout: 5))
        stay.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 5))
        XCTAssertTrue((app.textViews[AccessibilityID.field(.title).identifier].value as? String)?
            .contains("Edited") == true)
    }

    func testActiveRunOpensAssociatedCases() {
        let openRun = app.buttons[AccessibilityID.homeOpenRun.identifier]
        XCTAssertTrue(openRun.waitForExistence(timeout: 8))
        openRun.tap()
        XCTAssertTrue(app.staticTexts["Smoke · iOS 26"].waitForExistence(timeout: 8))
        let caseButton = app.buttons[AccessibilityID.entity(project: "DEMO", id: 2).identifier]
        XCTAssertTrue(caseButton.waitForExistence(timeout: 8))
        caseButton.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-2"].waitForExistence(timeout: 8))
    }
}
