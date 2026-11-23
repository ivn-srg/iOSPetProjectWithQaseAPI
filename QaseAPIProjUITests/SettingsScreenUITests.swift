import XCTest

/// Смоук вкладки Settings в демо: открытие, тема, очистка кеша, выход.
final class SettingsScreenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchDemo()
    }

    override func tearDownWithError() throws { app.terminate() }

    // Ловит: вкладка Settings не собирает экран настроек.
    func testSettingsTabOpens() {
        let settings = SettingsScreen.open(in: app)
        XCTAssertTrue(settings.row(.settingsLogout).exists)
    }

    // Ловит: выбор темы не записывается в настройки или строка Settings не показывает выбранную тему.
    func testThemeSelectionIsMarkedAndShown() {
        let settings = SettingsScreen.open(in: app)
        settings.row(.settingsAppearance).tap()
        let dark = app.buttons[AccessibilityID.appearance(.dark).identifier]
        XCTAssertTrue(dark.waitForExistence(timeout: 5), app.debugDescription)
        dark.tap()
        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == true"),
            object: dark
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed, app.debugDescription)
        XCTAssertFalse(app.buttons[AccessibilityID.appearance(.light).identifier].isSelected)
        XCTAssertFalse(app.buttons[AccessibilityID.appearance(.system).identifier].isSelected)
        settings.back()
        app.waitForLabel(settings.row(.settingsAppearance), containing: "Dark")
    }

    // Ловит: очистка не перечитывает состояние кеша или не сообщает об успехе.
    func testClearCacheReportsSuccess() {
        let settings = SettingsScreen.open(in: app)
        settings.row(.settingsCache).tap()
        XCTAssertTrue(app.staticTexts["Data available"].waitForExistence(timeout: 5), app.debugDescription)
        let clear = app.buttons[AccessibilityID.settingsCacheClear.identifier]
        XCTAssertTrue(clear.isEnabled)
        clear.tap()
        let confirm = app.dialogButton("Clear cache")
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        confirm.tap()
        XCTAssertTrue(app.staticTexts["Cache cleared"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.staticTexts["No cached data"].exists)
        XCTAssertFalse(clear.isEnabled)
    }

    // Ловит: отмена в диалоге выхода всё равно завершает сессию.
    func testSignOutCancelKeepsSettings() {
        let settings = SettingsScreen.open(in: app)
        settings.row(.settingsLogout).tap()
        let cancel = app.dialogButton("Cancel")
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), app.debugDescription)
        cancel.tap()
        app.waitForDisappearance(cancel)
        // Выход асинхронный: экран входа не должен появиться и спустя время, а не только сразу после тапа.
        let signedOut = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.descendants(matching: .any)[AccessibilityID.authScreen.identifier]
        )
        signedOut.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [signedOut], timeout: 3), .completed, app.debugDescription)
        XCTAssertTrue(app.buttons[AccessibilityID.settingsLogout.identifier].exists)
    }

    // Ловит: подтверждение выхода не завершает сессию и не возвращает на экран входа.
    func testSignOutReturnsToAuth() {
        let settings = SettingsScreen.open(in: app)
        settings.row(.settingsLogout).tap()
        let confirm = app.dialogButton("Sign out")
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        confirm.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)[AccessibilityID.authScreen.identifier]
                .waitForExistence(timeout: 8),
            app.debugDescription
        )
        XCTAssertTrue(app.buttons[AccessibilityID.authDemo.identifier].exists)
    }
}
