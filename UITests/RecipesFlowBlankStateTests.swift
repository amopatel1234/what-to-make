//
//  RecipesFlow.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


// RecipesFlowBlankStateTests.swift
import XCTest

final class RecipesFlowBlankStateTests: UITestBase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        launchApp(with: ["-ui-tests-blank"])
    }

    func testEmptyStateAddRecipeDeleteRecipe() {
        // Ensure Recipes tab is active
        let recipesTab = app.tabBars.buttons["Recipes"]
        waitForExistence(recipesTab, name: "Recipes Tab")
        recipesTab.tap()

        // Empty state visible (robust lookup via descendants)
        let emptyView = element(withId: "emptyRecipesView")
        waitForExistence(emptyView, name: "Empty Recipes View")

        // Open Add sheet
        let addButton = app.buttons["addRecipeButton"]
        tap(addButton, name: "Add Recipe Button")

        // Wait for sheet (Save button presence is a good proxy)
        let saveButton = app.buttons["saveRecipeButton"]
        waitForExistence(saveButton, name: "Save Recipe Button (Sheet Presented)")

        // Fields (scroll into view and force focus)
        let nameField = app.textFields["recipeNameField"]
        let notesField = app.textFields["notesField"]

        if !nameField.isHittable { app.swipeUp() }
        waitForHittable(nameField, name: "Recipe Name Field")
        nameField.tap()
        if !app.keyboards.keys.element(boundBy: 0).exists { nameField.tap() }
        clearAndType(nameField, text: "UI Test Dish", name: "Recipe Name Field")

        // ✅ New: add ingredients via dynamic flow
        addIngredient("Item A")
        addIngredient("Item B")

        if !notesField.isHittable { app.swipeUp() }
        waitForHittable(notesField, name: "Notes Field")
        notesField.tap()
        if !app.keyboards.keys.element(boundBy: 0).exists { notesField.tap() }
        clearAndType(notesField, text: "Quick note", name: "Notes Field")

        // Dismiss keyboard if covering Save
        if app.keyboards.keys.count > 0 {
            if app.keyboards.buttons["Return"].exists {
                app.keyboards.buttons["Return"].tap()
            } else {
                app.tap()
            }
        }

        // Save and wait for sheet to dismiss
        tap(saveButton, name: "Save Recipe Button")
        waitForHittable(addButton, name: "Add Recipe Button (after dismiss)")

        // Verify list via stable container ID
        let recipesList = element(withId: "recipesList")
        waitForExistence(recipesList, name: "Recipes List")

        let createdRow = app.staticTexts["recipeName_UI Test Dish"]
        XCTAssertTrue(createdRow.waitForExistence(timeout: 5), "Expected 'UI Test Dish' row to appear in list.")

        // Delete first row (type-agnostic cell)
        let firstCell = app.descendants(matching: .cell).element(boundBy: 0)
        waitForExistence(firstCell, name: "First Recipe Cell")
        firstCell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        tap(deleteButton, name: "Delete Button")

        // Back to empty state
        XCTAssertTrue(emptyView.waitForExistence(timeout: 5), "Expected empty state after deleting all recipes.")
    }
}
