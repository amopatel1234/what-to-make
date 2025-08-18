//
//  MenuFlow.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


// MenuFlowSeededTests.swift
import XCTest

final class MenuFlowSeededTests: UITestBase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        launchApp(with: ["-ui-tests-seeded"])
    }

    func testSeededRecipesExistAndGenerateMenuForTwoDays() {
        // Recipes tab shows seeded items
        let recipesTab = app.tabBars.buttons["Recipes"]
        tap(recipesTab, name: "Recipes Tab")

        let recipesList = element(withId: "recipesList")
        waitForExistence(recipesList, name: "Recipes List")
        XCTAssertGreaterThan(app.descendants(matching: .cell).count, 6, "Expected at least 7 seeded recipes.")

        // Go to Menu
        let menuTab = app.tabBars.buttons["Menu"]
        tap(menuTab, name: "Menu Tab")

        // Requirement message should reflect having enough recipes
        let requirement = app.staticTexts["menuRecipesRequirementMessage"]
        waitForExistence(requirement, name: "Requirement Message")
        XCTAssertTrue(requirement.label.contains("at least 7"))

        // Button disabled until a day is selected
        let generateButton = app.buttons["generateMenuButton"]
        waitForExistence(generateButton, name: "Generate Menu Button")
        XCTAssertFalse(generateButton.isEnabled, "Generate button should be disabled until at least one day is selected.")

        // Select Mon & Tue
        let monToggle = app.switches["toggleDay_Mon"]
        let tueToggle = app.switches["toggleDay_Tue"]
        ensureToggle(monToggle, on: true, dayLabel: "Mon", name: "Monday Toggle")
        ensureToggle(tueToggle, on: true, dayLabel: "Tue", name: "Tuesday Toggle")

        // Now enabled
        XCTAssertTrue(generateButton.isEnabled, "Generate button should be enabled with ≥7 recipes and days selected.")

        // Generate
        if !generateButton.isHittable { app.swipeUp() }
        tap(generateButton, name: "Generate Menu Button")

        // Verify rows (with scrolling helper you already have)
        _ = waitForElementWithScrolling(id: "menuItem_Mon", timeout: 6, name: "Monday menu row")
        XCTAssertTrue(app.descendants(matching: .any)["menuItem_Mon"].exists, "Expected Monday row.")

        _ = waitForElementWithScrolling(id: "menuItem_Tue", timeout: 6, name: "Tuesday menu row")
        XCTAssertTrue(app.descendants(matching: .any)["menuItem_Tue"].exists, "Expected Tuesday row.")
    }


    func testGenerateMenuNoDaysSelectedShowsDisabledButtonAndNoRows() {
        // Go to Menu tab
        let menuTab = app.tabBars.buttons["Menu"]
        tap(menuTab, name: "Menu Tab")

        // Ensure both toggles are OFF (uses robust helper that can tap label/coordinate if needed)
        let monToggle = app.switches["toggleDay_Mon"]
        let tueToggle = app.switches["toggleDay_Tue"]
        ensureToggle(monToggle, on: false, dayLabel: "Mon", name: "Monday Toggle")
        ensureToggle(tueToggle, on: false, dayLabel: "Tue", name: "Tuesday Toggle")

        // Generate button should exist and be disabled
        let generateButton = app.buttons["generateMenuButton"]
        waitForExistence(generateButton, name: "Generate Menu Button")
        XCTAssertFalse(generateButton.isEnabled, "Generate button should be disabled when no days are selected.")

        // Since the button is disabled, no validation message should appear automatically
        let validation = app.staticTexts["menuValidationMessage"]
        XCTAssertFalse(validation.exists, "Validation message should not be visible until an action occurs.")

        // No menu rows should be present
        XCTAssertFalse(app.descendants(matching: .any)["menuItem_Mon"].exists, "Should not see Monday row with no selection.")
        XCTAssertFalse(app.descendants(matching: .any)["menuItem_Tue"].exists, "Should not see Tuesday row with no selection.")
    }

}
