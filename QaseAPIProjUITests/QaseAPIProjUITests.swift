//
//  QaseAPIProjUITests.swift
//  QaseAPIProjUITests
//
//  Created by Sergey Ivanov on 01.04.2025.
//

import XCTest

final class QaseAPIProjUITests: XCTestCase {
    
    private var app: XCUIApplication!
    private var authScreen: AuthScreen!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launchArguments.append("UITests")
        app.launch()

        authScreen = AuthScreen(app: app)
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.terminate()
    }
    
    @MainActor
    func testCheckNavigationTitle() throws {
        authScreen.openProjects().checkNavigationTitle()
    }
    
    @MainActor
    func testPresentCreatingProjectScreen() throws {
        authScreen.openProjects().openCreateProject().checkPresented()
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
