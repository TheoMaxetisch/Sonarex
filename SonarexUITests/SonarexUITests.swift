import XCTest

/// UI-Smoke-Tests fuer die wichtigsten Navigations- und Eingabepfade.
final class SonarexUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainTabsAreReachable() throws {
        // Stellt sicher, dass alle Hauptbereiche ueber die Tabbar erreichbar bleiben.
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        XCTAssertTrue(tabBar.buttons["Feed"].exists)
        XCTAssertTrue(tabBar.buttons["Suche"].exists)
        XCTAssertTrue(tabBar.buttons["Bibliothek"].exists)
        XCTAssertTrue(tabBar.buttons["Setup"].exists)

        tabBar.buttons["Suche"].tap()
        XCTAssertTrue(app.staticTexts["Suche"].waitForExistence(timeout: 2))

        tabBar.buttons["Bibliothek"].tap()
        XCTAssertTrue(app.staticTexts["Bibliothek"].waitForExistence(timeout: 2))

        tabBar.buttons["Setup"].tap()
        XCTAssertTrue(app.staticTexts["Einstellungen"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSearchFlowAcceptsInputAndCanBeCleared() throws {
        // Prueft den zentralen Suchflow inklusive Loeschen des Suchtexts.
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Suche"].tap()

        let searchField = app.textFields["Songs, Artists oder Kategorien"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))

        searchField.tap()
        searchField.typeText("Golden")

        let clearSearchButton = app.buttons["Suche leeren"]
        XCTAssertTrue(clearSearchButton.waitForExistence(timeout: 2))
        clearSearchButton.tap()

        XCTAssertEqual(searchField.value as? String, "Songs, Artists oder Kategorien")
    }

    @MainActor
    func testSettingsPremiumFlowOpensPaywall() throws {
        // Der Premium-Einstieg ist wichtig, weil mehrere Funktionen darueber begrenzt werden.
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["Setup"].tap()

        let premiumButton = app.buttons["Premium verwalten"]
        XCTAssertTrue(premiumButton.waitForExistence(timeout: 2))
        premiumButton.tap()

        XCTAssertTrue(app.navigationBars["Sonarex Premium"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Schließen"].exists)
    }
}
