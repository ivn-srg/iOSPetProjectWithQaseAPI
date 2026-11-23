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
        let picker = app.buttons[AccessibilityID.projectPicker.identifier]
        app.waitForLabel(picker, containing: "1Forma")
        app.selectTab(.tabRepository, title: "Репозиторий")
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        app.waitForLabel(picker, containing: "1Forma")
        app.selectTab(.tabWork, title: "Работа")
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        app.waitForLabel(picker, containing: "1Forma")
    }

    func testCaseOpenAddsRecentEntryAndSearchWorks() {
        app.buttons[AccessibilityID.homeAllCases.identifier].tap()
        let row = reveal(.repositoryCase(81))
        row.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 8))
        app.navigationBars.buttons[AccessibilityID.formBack.identifier].tap()
        app.selectTab(.tabHome, title: "Главная")
        XCTAssertTrue(app.buttons[AccessibilityID.recent(project: "DEMO", caseID: 81).identifier]
            .waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Home light recent"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons[AccessibilityID.homeSearchCases.identifier].tap()
        let field = app.textFields[AccessibilityID.repositorySearch.identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForKeyboardFocus(field, focused: true), app.debugDescription)
        field.tap()
        field.typeText("Кейс верхнего")
        let match = app.buttons[AccessibilityID.repositoryCase(81).identifier]
        XCTAssertTrue(match.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertFalse(app.descendants(matching: .any)[AccessibilityID.repositoryCase(2).identifier].exists)
        let caseRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "repository.case.")
        )
        XCTAssertEqual(caseRows.count, 1, app.debugDescription)
        _ = reveal(.repositoryCase(81))
    }

    func testSearchFocusIsAppliedOncePerRequest() {
        app.buttons[AccessibilityID.homeSearchCases.identifier].tap()
        let field = app.textFields[AccessibilityID.repositorySearch.identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForKeyboardFocus(field, focused: true), app.debugDescription)
        field.typeText("Кейс верхнего")
        let match = app.buttons[AccessibilityID.repositoryCase(81).identifier]
        XCTAssertTrue(match.waitForExistence(timeout: 8), app.debugDescription)
        match.tap()
        XCTAssertTrue(app.navigationBars.staticTexts["DEMO-81"].waitForExistence(timeout: 8))
        let back = app.navigationBars.buttons[AccessibilityID.formBack.identifier]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(field.waitForExistence(timeout: 8), app.debugDescription)
        // Возврат с кейса не должен вернуть полю фокус (проверка фокуса, а не клавиатуры:
        // при аппаратной клавиатуре симулятора программная не показывается).
        XCTAssertFalse(waitForKeyboardFocus(field, focused: true, timeout: 2), app.debugDescription)
    }

    /// Ждёт, пока у элемента появится (или пропадёт) фокус ввода.
    private func waitForKeyboardFocus(_ element: XCUIElement, focused: Bool, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasKeyboardFocus == %@", NSNumber(value: focused)),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func testLongPressOffersDeleteWithConfirmation() {
        app.selectTab(.tabRepository, title: "Репозиторий")
        let row = reveal(.repositoryCase(1000))
        row.press(forDuration: 1.0)
        let delete = app.buttons["Удалить"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), app.debugDescription)
        delete.tap()
        let title = app.staticTexts["Удалить кейс?"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), app.debugDescription)
        let cancel = app.buttons["Отмена"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), app.debugDescription)
        cancel.tap()
        app.waitForDisappearance(title)
        XCTAssertTrue(app.descendants(matching: .any)[AccessibilityID.repositoryCase(1000).identifier]
            .waitForExistence(timeout: 5), app.debugDescription)
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
        app.selectTab(.tabHome, title: "Главная")
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
