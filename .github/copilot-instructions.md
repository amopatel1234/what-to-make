You are helping on an iOS app called "WeeklyMenu". Follow these constraints:
- iOS app in Swift, SwiftUI UI, SwiftData persistence, Swift Concurrency async/await only.
- No Combine, no force-unwraps, verbose camelCase names.
- Use SOLID principles, clean architecture with Use Cases + Repository pattern.
- Recipes: name (required), notes (optional), optional photo via PhotosPicker. No ingredients.
- Menu generation: disabled unless ≥7 recipes. User can select any days Mon–Sun. Increments recipe usageCount on generate.
- AppState: @Observable, injected via environment, has refreshCounter to trigger view reloads.
- Accessibility IDs required on all controls for UI tests (recipesList, emptyRecipesView, addRecipeButton, recipeNameField, notesField, choosePhotoButton, saveRecipeButton, toggleDay_<Day>, generateMenuButton, menuItem_<Day>, menuRecipesRequirementMessage, menuValidationMessage, debug_*).
- Debug menu in debug builds or via -debug-menu arg: clear DB, seed recipes/menu, reset usage, refresh AppState.
- In UI, render menu rows from snapshot values (day + recipe name) not live model objects to avoid diff crashes.
- Tests: Swift Testing for units, XCUITest for UI. No mixing of prod/test code unless necessary for debug seeding.

