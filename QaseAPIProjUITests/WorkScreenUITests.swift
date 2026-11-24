import XCTest

/// Смоук вкладки Work в демо: списки запусков и дефектов открываются и показывают данные проекта.
final class WorkScreenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchDemo()
    }

    override func tearDownWithError() throws { app.terminate() }

    // Ловит: строки Runs/Defects ведут не на свой список или список не показывает данные проекта.
    func testRunsAndDefectsListsShowProjectData() {
        let work = WorkScreen.open(in: app)
        work.open(.workRuns)
        XCTAssertTrue(app.staticTexts["Smoke · iOS 26"].waitForExistence(timeout: 8), app.debugDescription)
        app.waitForLabel(app.staticTexts[AccessibilityID.workProject.identifier], containing: "Demo Project")
        XCTAssertFalse(app.staticTexts["Ошибка входа после смены домена"].exists)
        work.back()
        work.open(.workDefects)
        XCTAssertTrue(
            app.staticTexts["Ошибка входа после смены домена"].waitForExistence(timeout: 8),
            app.debugDescription
        )
        XCTAssertFalse(app.staticTexts["Smoke · iOS 26"].exists)
    }
}
