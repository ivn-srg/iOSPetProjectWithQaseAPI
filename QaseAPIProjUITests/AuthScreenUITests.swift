import XCTest

final class AuthScreenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITests", "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
    }

    override func tearDownWithError() throws { app.terminate() }

    func testEmptyFormAndVisibleDemoEntry() {
        let field = app.secureTextFields[AccessibilityID.inputTextField.identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons[AccessibilityID.authButton.identifier].isEnabled)
        XCTAssertTrue(app.staticTexts["Войти в Qase"].exists)
        XCTAssertFalse(app.staticTexts["Без API-токена, на демонстрационных данных"].exists)
        let demo = reveal(.authDemo)
        XCTAssertTrue(demo.isEnabled)
        demo.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].waitForExistence(timeout: 12))
    }

    func testVisibilityAndKeyboardKeepEnteredToken() {
        let field = app.secureTextFields[AccessibilityID.inputTextField.identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("fixture-token")
        XCTAssertTrue(reveal(.authButton).isEnabled)
        reveal(.authTokenVisibility).tap()
        let visible = app.textFields[AccessibilityID.inputTextField.identifier]
        XCTAssertTrue(visible.waitForExistence(timeout: 5))
        XCTAssertEqual(visible.value as? String, "fixture-token")
        reveal(.authTokenVisibility).tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("X")
        reveal(.authTokenVisibility).tap()
        XCTAssertEqual(visible.value as? String, "fixture-tokenX")
    }

    func testLegacyLongPressStillOpensDemo() {
        let logo = app.images[AccessibilityID.logoImg.identifier]
        XCTAssertTrue(logo.waitForExistence(timeout: 5))
        logo.press(forDuration: 2)
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].waitForExistence(timeout: 12))
    }

    func testLargeTextAllowsReachingDemo() {
        app.terminate()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        XCTAssertTrue(app.secureTextFields[AccessibilityID.inputTextField.identifier]
            .waitForExistence(timeout: 5))
        reveal(.authDemo).tap()
        XCTAssertTrue(app.buttons[AccessibilityID.projectPicker.identifier].waitForExistence(timeout: 12))
    }

    private func reveal(_ identifier: AccessibilityID) -> XCUIElement {
        let element = app.descendants(matching: .any).matching(identifier: identifier.identifier).firstMatch
        for _ in 0 ..< 6 {
            if element.exists && element.isHittable { return element }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable)
        return element
    }
}
