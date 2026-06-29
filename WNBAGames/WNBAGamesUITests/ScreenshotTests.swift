import XCTest

/// Drives the app through its primary screens and writes full-screen PNGs to the
/// UI-test runner's Documents directory. Pull them off the simulator afterward with:
///   xcrun simctl get_app_container <udid> com.phred.WNBAGamesIOSUITests.xctrunner data
final class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testCaptureScreens() {
        // Games list (default tab) — let live data load.
        waitForGames()
        snap("01-games")

        // Game detail via the first row's Details button.
        let details = app.buttons["Details"].firstMatch
        if details.waitForExistence(timeout: 5) {
            details.tap()
            sleep(2)
            snap("02-detail")
            back()
        }

        // Standings.
        tapTab("Standings")
        sleep(3)
        snap("04-standings")

        // Leaders.
        tapTab("Leaders")
        sleep(3)
        snap("05-leaders")

        // Settings.
        tapTab("Settings")
        sleep(1)
        snap("06-settings")
    }

    // MARK: - Helpers

    private func waitForGames() {
        // Wait until at least one game row's Details button shows up (data loaded).
        let anyRow = app.buttons["Details"].firstMatch
        _ = anyRow.waitForExistence(timeout: 20)
        sleep(1)
    }

    private func tapTab(_ label: String) {
        let inTabBar = app.tabBars.buttons[label]
        if inTabBar.waitForExistence(timeout: 3) {
            inTabBar.tap()
            return
        }
        // iPad / floating tab bar renders tabs as plain buttons.
        let plain = app.buttons[label].firstMatch
        if plain.waitForExistence(timeout: 3) {
            plain.tap()
        }
    }

    private func back() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
            sleep(1)
        }
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()

        // Attach to the result bundle (handy if pulled via xcresulttool).
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also write a PNG we can pull straight off the simulator container.
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("\(name).png")
        do {
            try shot.pngRepresentation.write(to: url)
        } catch {
            XCTFail("Failed to write \(name): \(error)")
        }
    }
}
