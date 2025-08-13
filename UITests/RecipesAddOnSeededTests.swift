//
//  Recipes.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


// RecipesAddOnSeededTests.swift
import XCTest

final class RecipesAddOnSeededTests: UITestBase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        launchApp(with: ["-ui-tests-seeded"])
    }

    func testAddAnotherRecipeOnSeededStore() {
        let recipesTab = app.tabBars.buttons["Recipes"]
        tap(recipesTab, name: "Recipes Tab")

        // Open Add sheet
        let addButton = app.buttons["addRecipeButton"]
        tap(addButton, name: "Add Recipe Button")

        // Wait for sheet to be fully ready (Save button visible is a good proxy)
        let saveButton = app.buttons["saveRecipeButton"]
        waitForExistence(saveButton, name: "Save Recipe Button (Sheet Presented)")

        // Fields
        let nameField = app.textFields["recipeNameField"]
        
        // Ensure fields are visible & focusable; scroll if needed
        // (List-backed forms can be off-screen on smaller devices)
        if !nameField.isHittable { app.swipeUp() }
        waitForHittable(nameField, name: "Recipe Name Field")
        // Force a real tap to get keyboard focus (some UIs need 2 taps)
        nameField.tap()
        if !app.keyboards.keys.element(boundBy: 0).exists { nameField.tap() }

        clearAndType(nameField, text: "Extra Dish", name: "Recipe Name Field")

        addIngredient("X")
        addIngredient("Y")

        // If the keyboard is covering Save on small devices, dismiss it
        if app.keyboards.keys.count > 0 {
            // Try common actions to dismiss keyboard
            if app.keyboards.buttons["Return"].exists {
                app.keyboards.buttons["Return"].tap()
            } else {
                app.tap() // generic tap outside
            }
        }

        tap(saveButton, name: "Save Recipe Button")

        // Verify
        let list = element(withId: "recipesList")
        waitForExistence(list, name: "Recipes List")
        XCTAssertTrue(
            app.staticTexts["recipeName_Extra Dish"].waitForExistence(timeout: 5),
            "Expected 'Extra Dish' row to appear after saving."
        )
    }

}
