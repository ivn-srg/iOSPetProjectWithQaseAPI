import XCTest

final class HomeScreenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITests", "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        let logo = app.images["logoImg"]
        XCTAssertTrue(logo.waitForExistence(timeout: 5))
        logo.press(forDuration: 2)
        XCTAssertTrue(app.buttons["project.picker"].waitForExistence(timeout: 12))
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Demo Project"), object: app.buttons["project.picker"])
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 12), .completed)
    }

    override func tearDownWithError() throws { app.terminate() }

    private func reveal(_ identifier: String) -> XCUIElement {
        let item = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        for _ in 0..<8 {
            if item.exists && item.isHittable { return item }
            app.swipeUp()
        }
        XCTAssertTrue(item.exists && item.isHittable, app.debugDescription)
        return item
    }

    func testProjectChoiceIsSharedAcrossTabs() {
        app.buttons["project.picker"].tap()
        let choice = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "1Forma")).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        XCTAssertTrue(app.buttons["project.picker"].label.contains("1Forma"))
        app.tabBars.buttons["Репозиторий"].tap()
        XCTAssertTrue(app.buttons["project.picker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["project.picker"].label.contains("1Forma"))
        app.tabBars.buttons["Работа"].tap()
        XCTAssertTrue(app.buttons["project.picker"].label.contains("1Forma"))
    }

    func testCaseOpenAddsRecentEntryAndSearchWorks() {
        app.buttons["Все кейсы"].tap()
        let row = reveal("repository.case.81")
        row.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 8))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Главная"].tap()
        XCTAssertTrue(app.buttons["recent.DEMO-81"].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Home light recent"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Поиск кейсов"].tap()
        let field = app.textFields["repository.search"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Кейс верхнего")
        _ = reveal("repository.case.81")
    }

    func testLargeTextLayout() {
        XCTAssertTrue(app.buttons["project.picker"].isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Home accessibility"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let cases = app.buttons["Все кейсы"]
        for _ in 0..<6 where !cases.isHittable { app.swipeUp() }
        XCTAssertTrue(cases.isHittable)
        cases.tap()
        _ = reveal("repository.case.81")
    }

    func testHierarchyAndBreadcrumbs() {
        app.buttons["Все кейсы"].tap()
        let suite = app.buttons["repository.suite.81"]
        XCTAssertTrue(suite.waitForExistence(timeout: 8))
        suite.tap()
        let child = app.buttons["repository.suite.82"]
        XCTAssertTrue(child.waitForExistence(timeout: 8))
        child.tap()
        XCTAssertTrue(app.buttons["repository.suite.86"].waitForExistence(timeout: 8))
        app.buttons["repository.breadcrumb.root"].tap()
        XCTAssertTrue(app.buttons["repository.suite.81"].waitForExistence(timeout: 8))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Repository root"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testHiddenDraftSurvivesCancelledRootNavigation() {
        app.buttons["Все кейсы"].tap()
        let row = reveal("repository.case.81")
        row.tap()
        let title = app.textViews["field.Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 8))
        title.tap()
        title.typeText(" Edited")
        app.tabBars.buttons["Главная"].tap()
        app.buttons["Все кейсы"].tap()
        let stay = app.alerts.buttons["Остаться"]
        XCTAssertTrue(stay.waitForExistence(timeout: 5))
        stay.tap()
        app.tabBars.buttons["Репозиторий"].tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 5))
        XCTAssertTrue((app.textViews["field.Title"].value as? String)?.contains("Edited") == true)
    }

    func testActiveRunOpensAssociatedCases() {
        let openRun = app.buttons["Открыть запуск"]
        XCTAssertTrue(openRun.waitForExistence(timeout: 8))
        openRun.tap()
        XCTAssertTrue(app.staticTexts["Smoke · iOS 26"].waitForExistence(timeout: 8))
        let caseButton = app.buttons["DEMO-2"]
        XCTAssertTrue(caseButton.waitForExistence(timeout: 8))
        caseButton.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-2"].waitForExistence(timeout: 8))
    }
}
