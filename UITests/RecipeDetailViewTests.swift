//
//  RecipeDetailViewTests.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import XCTest

final class RecipeDetailViewTests: UITestBase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        launchApp(with: ["-ui-tests-seeded"])
    }

    func testNavigateToRecipeDetailView() {
        // Ensure Recipes tab is active
        let recipesTab = app.tabBars.buttons["Recipes"]
        waitForExistence(recipesTab, name: "Recipes Tab")
        recipesTab.tap()

        // Wait for recipe list to load
        let recipesList = element(withId: "recipesList")
        waitForExistence(recipesList, name: "Recipes List")

        // Find and tap on the first recipe row
        let firstRecipeRow = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'recipeRow_'")).element(boundBy: 0)
        waitForExistence(firstRecipeRow, name: "First Recipe Row")
        tap(firstRecipeRow, name: "First Recipe Row")

        // Verify detail view is shown
        let detailView = element(withId: "recipeDetailView")
        waitForExistence(detailView, name: "Recipe Detail View")

        // Verify navigation title shows recipe name (back button should be visible)
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        waitForExistence(backButton, name: "Back Button")

        // Verify key elements are present
        let usageLabel = element(withId: "recipeDetailUsageLabel")
        waitForExistence(usageLabel, name: "Usage Count Label")

        let usageCount = element(withId: "recipeDetailUsageCount")
        waitForExistence(usageCount, name: "Usage Count Value")
    }

    func testRecipeDetailViewContent() {
        // Navigate to recipes list
        let recipesTab = app.tabBars.buttons["Recipes"]
        waitForExistence(recipesTab, name: "Recipes Tab")
        recipesTab.tap()

        // Wait for recipe list and tap first recipe
        let recipesList = element(withId: "recipesList")
        waitForExistence(recipesList, name: "Recipes List")

        let firstRecipeRow = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'recipeRow_'")).element(boundBy: 0)
        waitForExistence(firstRecipeRow, name: "First Recipe Row")
        tap(firstRecipeRow, name: "First Recipe Row")

        // Verify detail view content
        let detailView = element(withId: "recipeDetailView")
        waitForExistence(detailView, name: "Recipe Detail View")

        // Check for usage count section
        let usageLabel = element(withId: "recipeDetailUsageLabel")
        XCTAssertTrue(usageLabel.exists, "Usage count label should be visible")

        let usageCount = element(withId: "recipeDetailUsageCount")
        XCTAssertTrue(usageCount.exists, "Usage count value should be visible")

        // Check for notes section (may or may not exist depending on recipe)
        let notesLabel = element(withId: "recipeDetailNotesLabel")
        if notesLabel.exists {
            let notesText = element(withId: "recipeDetailNotesText")
            XCTAssertTrue(notesText.exists, "If notes label exists, notes text should also exist")
        }

        // Check for image (could be original, thumbnail, or placeholder)
        let hasImage = element(withId: "recipeDetailImage").exists ||
                      element(withId: "recipeDetailThumbnail").exists ||
                      element(withId: "recipeDetailNoImage").exists
        XCTAssertTrue(hasImage, "Some form of image display should be present")
    }

    func testNavigateBackFromDetailView() {
        // Navigate to recipes and then to detail
        let recipesTab = app.tabBars.buttons["Recipes"]
        waitForExistence(recipesTab, name: "Recipes Tab")
        recipesTab.tap()

        let recipesList = element(withId: "recipesList")
        waitForExistence(recipesList, name: "Recipes List")

        let firstRecipeRow = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'recipeRow_'")).element(boundBy: 0)
        waitForExistence(firstRecipeRow, name: "First Recipe Row")
        tap(firstRecipeRow, name: "First Recipe Row")

        // Verify we're on detail view
        let detailView = element(withId: "recipeDetailView")
        waitForExistence(detailView, name: "Recipe Detail View")

        // Navigate back
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        waitForExistence(backButton, name: "Back Button")
        tap(backButton, name: "Back Button")

        // Verify we're back on the recipes list
        waitForExistence(recipesList, name: "Recipes List (after back)")
        XCTAssertFalse(detailView.exists, "Detail view should not be visible after navigating back")
    }
}