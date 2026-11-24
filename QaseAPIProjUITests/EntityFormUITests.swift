import XCTest

/// Форма создания набора/кейса: закрытие с подтверждением и выбор родителя.
final class EntityFormUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchDemo()
        app.selectTab(.tabRepository, title: "Repository")
    }

    override func tearDownWithError() throws { app.terminate() }

    private var repositoryScreen: XCUIElement {
        app.descendants(matching: .any)[AccessibilityID.repositoryScreen.identifier]
    }

    private func openForm() -> EntityFormScreen {
        let create = app.buttons[AccessibilityID.repositoryCreate.identifier]
        XCTAssertTrue(create.waitForExistence(timeout: 8), app.debugDescription)
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: create
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 8), .completed, app.debugDescription)
        create.tap()
        let form = EntityFormScreen(app: app)
        XCTAssertTrue(form.titleField.waitForExistence(timeout: 5), app.debugDescription)
        return form
    }

    // Ловит: закрытие изменённой формы без подтверждения или потеря текста после «Continue editing».
    func testClosingEditedFormAsksAndKeepsDraftOnStay() {
        let form = openForm()
        form.enterTitle("Draft suite")
        form.close()
        form.confirmStay()
        XCTAssertTrue(form.titleField.waitForExistence(timeout: 5))
        XCTAssertTrue(
            (form.titleField.value as? String)?.contains("Draft suite") == true,
            app.debugDescription
        )
        form.close()
        form.confirmDiscard()
        XCTAssertTrue(repositoryScreen.waitForExistence(timeout: 5), app.debugDescription)
        app.waitForDisappearance(app.buttons[AccessibilityID.formClose.identifier])
    }

    // Ловит: подтверждение ухода требуется и для неизменённой формы.
    func testClosingCleanFormDismissesImmediately() {
        let form = openForm()
        form.close()
        app.waitForDisappearance(app.buttons[AccessibilityID.formClose.identifier])
        XCTAssertTrue(repositoryScreen.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(app.alerts["Discard changes?"].exists)
    }

    // Ловит: Cancel в выборе родителя меняет значение; выбор корня не применяется к форме.
    func testParentPickerCancelKeepsSuiteAndRootReplacesIt() {
        let suite = app.buttons[AccessibilityID.repositorySuite(81).identifier]
        XCTAssertTrue(suite.waitForExistence(timeout: 8), app.debugDescription)
        suite.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.repositorySuite(82).identifier]
            .waitForExistence(timeout: 8))
        let form = openForm()
        app.waitForLabel(form.parentButton, containing: "ВКС")
        form.openParentPicker().cancel()
        app.waitForDisappearance(app.buttons[AccessibilityID.suitePickerClose.identifier])
        app.waitForLabel(form.parentButton, containing: "ВКС")
        form.openParentPicker().chooseRoot()
        app.waitForLabel(form.parentButton, containing: "Project root")
    }
}
