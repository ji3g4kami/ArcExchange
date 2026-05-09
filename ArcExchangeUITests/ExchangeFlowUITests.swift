import XCTest

@MainActor
final class ExchangeFlowUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func makeApp(launchArgs: [String] = ["-UITestStubSuccess", "1"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += launchArgs
        return app
    }

    func test_launch_shows_USDc_and_default_foreign_currency() {
        let app = makeApp()
        app.launch()

        let usdcLabel = app.buttons["label.usdc"].firstMatch
        XCTAssertTrue(usdcLabel.waitForExistence(timeout: 5))

        let foreignLabel = app.buttons["label.foreign"].firstMatch
        XCTAssertTrue(foreignLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(foreignLabel.label.contains("MXN"))

        let usdcField = app.textFields["amount.usdc"].firstMatch
        XCTAssertTrue(usdcField.waitForExistence(timeout: 5))
    }

    func test_header_shows_title_and_green_rate_line() {
        let app = makeApp()
        app.launch()

        let title = app.staticTexts["Exchange calculator"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        let rateLine = app.staticTexts["text.rateLine"].firstMatch
        XCTAssertTrue(rateLine.waitForExistence(timeout: 5))
        XCTAssertTrue(rateLine.label.contains("USDc ="))
    }

    func test_typing_into_USDc_updates_foreign_field() {
        let app = makeApp()
        app.launch()

        let usdcField = app.textFields["amount.usdc"].firstMatch
        XCTAssertTrue(usdcField.waitForExistence(timeout: 5))
        usdcField.tap()
        usdcField.typeText("10")

        let foreignField = app.textFields["amount.foreign"].firstMatch
        let predicate = NSPredicate(format: "value != '' AND value != '0'")
        let expectation = expectation(for: predicate, evaluatedWith: foreignField)
        wait(for: [expectation], timeout: 5)
    }

    func test_typing_into_foreign_updates_USDc_field() {
        let app = makeApp()
        app.launch()

        let foreignField = app.textFields["amount.foreign"].firstMatch
        XCTAssertTrue(foreignField.waitForExistence(timeout: 5))
        foreignField.tap()
        foreignField.typeText("200")

        let usdcField = app.textFields["amount.usdc"].firstMatch
        let predicate = NSPredicate(format: "value != '' AND value != '0'")
        let expectation = expectation(for: predicate, evaluatedWith: usdcField)
        wait(for: [expectation], timeout: 5)
    }

    func test_tapping_foreign_label_opens_picker_and_selects_BRL() {
        let app = makeApp()
        app.launch()

        let foreignLabel = app.buttons["label.foreign"].firstMatch
        XCTAssertTrue(foreignLabel.waitForExistence(timeout: 5))
        foreignLabel.tap()

        let brlRow = app.buttons["picker.row.BRL"].firstMatch
        XCTAssertTrue(brlRow.waitForExistence(timeout: 5))
        brlRow.tap()

        let predicate = NSPredicate(format: "label CONTAINS 'BRL'")
        let updatedLabel = expectation(for: predicate, evaluatedWith: foreignLabel)
        wait(for: [updatedLabel], timeout: 5)
    }

    func test_swap_button_flips_currency_positions() {
        let app = makeApp()
        app.launch()

        let usdcField = app.textFields["amount.usdc"].firstMatch
        XCTAssertTrue(usdcField.waitForExistence(timeout: 5))

        let usdcFrameBefore = usdcField.frame
        let foreignField = app.textFields["amount.foreign"].firstMatch
        let foreignFrameBefore = foreignField.frame

        let swap = app.buttons["button.swap"].firstMatch
        XCTAssertTrue(swap.waitForExistence(timeout: 5))
        swap.tap()

        let usdcFieldAfter = app.textFields["amount.usdc"].firstMatch
        let foreignFieldAfter = app.textFields["amount.foreign"].firstMatch

        let deadline = Date().addingTimeInterval(5)
        var swapped = false
        while Date() < deadline {
            let usdcMoved = usdcFieldAfter.frame.minY != usdcFrameBefore.minY
            let foreignMoved = foreignFieldAfter.frame.minY != foreignFrameBefore.minY
            if usdcMoved && foreignMoved {
                swapped = true
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertTrue(swapped, "Expected USDc and foreign rows to swap vertical positions after swap")
    }

    func test_network_failure_shows_error_banner_with_retry() {
        let app = makeApp(launchArgs: ["-UITestStubFailure", "1"])
        app.launch()

        let retry = app.buttons["button.retry"].firstMatch
        XCTAssertTrue(retry.waitForExistence(timeout: 8), "Retry button should appear when service fails")

        let bannerByDescendant = app.descendants(matching: .any)["banner.error"]
        XCTAssertTrue(bannerByDescendant.waitForExistence(timeout: 5), "Error banner should be visible")

        retry.tap()
        XCTAssertTrue(retry.waitForExistence(timeout: 5), "Retry button should remain (still failing)")
    }
}
