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

extension XCUIApplication {
    /// Запуск в режиме UI-тестов на выбранном языке; демо-вход и ожидание загрузки демо-проекта.
    func launchDemo(language: String = "en", locale: String = "en_US") {
        launchArguments = ["UITests", "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        launch()
        let demo = buttons[AccessibilityID.authDemo.identifier]
        XCTAssertTrue(demo.waitForExistence(timeout: 5))
        if !demo.isHittable { swipeUp() }
        demo.tap()
        let picker = buttons[AccessibilityID.projectPicker.identifier]
        XCTAssertTrue(picker.waitForExistence(timeout: 12))
        waitForLabel(picker, containing: "Demo Project")
    }

    func selectTab(
        _ identifier: AccessibilityID,
        title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let identified = tabBars.buttons[identifier.identifier]
        let button = identified.exists ? identified : tabBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 5), debugDescription, file: file, line: line)
        button.tap()
    }

    func waitForLabel(
        _ element: XCUIElement,
        containing text: String,
        timeout: TimeInterval = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", text),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, debugDescription,
            file: file, line: line
        )
    }

    func waitForDisappearance(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, debugDescription,
            file: file, line: line
        )
    }

    /// Кнопка подтверждения внутри диалога: у строки экрана и кнопки диалога одинаковые подписи.
    /// Контейнер выбирается после появления диалога, а не по снимку во время анимации.
    func dialogButton(_ title: String, timeout: TimeInterval = 5) -> XCUIElement {
        let sheet = sheets.firstMatch
        let alert = alerts.firstMatch
        let shown = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in sheet.exists || alert.exists },
            object: nil
        )
        _ = XCTWaiter.wait(for: [shown], timeout: timeout)
        return (sheet.exists ? sheet : alert).buttons[title]
    }

    /// Возврат на предыдущий экран навигации.
    func tapBack() {
        let back = navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
    }
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
        wait(field, "isHittable == true")
        // Проверено зондом (журнал плана E2, 2026-11-24): у пустого поля `tap()` фокуса не даёт даже дважды,
        // координатное касание в центр — даёт. Активация пустого поля через VoiceOver — ручная проверка.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        wait(field, "hasKeyboardFocus == true")
        field.typeText(value)
    }

    private func wait(_ element: XCUIElement, _ format: String) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: format), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, app.debugDescription)
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

    var titleField: XCUIElement { app.textViews[AccessibilityID.field(.title).identifier] }
    var parentButton: XCUIElement { app.buttons[AccessibilityID.field(.parentSuite).identifier] }

    func close() {
        let close = app.buttons[AccessibilityID.formClose.identifier]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
    }

    /// Ответ на «Discard changes?»: остаться в форме.
    func confirmStay() { answerDeparture("Continue editing") }

    /// Ответ на «Discard changes?»: сбросить черновик и закрыть форму.
    func confirmDiscard() { answerDeparture("Discard changes") }

    private func answerDeparture(_ title: String) {
        let alert = app.alerts["Discard changes?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), app.debugDescription)
        alert.buttons[title].tap()
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

struct SettingsScreen: Screen {
    let app: XCUIApplication

    static func open(in app: XCUIApplication) -> SettingsScreen {
        app.selectTab(.tabSettings, title: "Settings")
        XCTAssertTrue(
            app.descendants(matching: .any)[AccessibilityID.settingsScreen.identifier]
                .waitForExistence(timeout: 5),
            app.debugDescription
        )
        return SettingsScreen(app: app)
    }

    func row(_ identifier: AccessibilityID) -> XCUIElement {
        let row = app.buttons[identifier.identifier]
        for _ in 0 ..< 4 where !(row.exists && row.isHittable) { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5), app.debugDescription)
        return row
    }

    func back() { app.tapBack() }
}

struct WorkScreen: Screen {
    let app: XCUIApplication

    static func open(in app: XCUIApplication) -> WorkScreen {
        app.selectTab(.tabWork, title: "Work")
        return WorkScreen(app: app)
    }

    func open(_ list: AccessibilityID) {
        let row = app.buttons[list.identifier]
        XCTAssertTrue(row.waitForExistence(timeout: 8), app.debugDescription)
        row.tap()
    }

    func back() { app.tapBack() }
}
