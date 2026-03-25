//  SwipeSweepUITests.swift
//  SwipeSweepUITests
//
//  Created by Gray Gillman on 3/24/26.

import XCTest

final class SwipeSweepUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // Wait for app to load
        sleep(3)

        // 1. Main swipe screen
        snapshot("01_MainScreen")

        // 2. Tap the archive/deleted button (archivebox icon - top left)
        let archiveButton = app.buttons["archivebox.fill"]
        if archiveButton.waitForExistence(timeout: 3) {
            archiveButton.tap()
            sleep(2)
            snapshot("02_DeletedPhotos")
            // Dismiss sheet
            app.swipeDown()
            sleep(1)
        }

        // 3. Tap settings button (gearshape icon - top right)
        let settingsButton = app.buttons["gearshape"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
            sleep(2)
            snapshot("03_Settings")
        }
    }
}
