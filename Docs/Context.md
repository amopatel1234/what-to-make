# WeeklyMenu App – Engineering Context

## Tech Stack & Rules
- iOS app built in Swift using Xcode.
- **SwiftUI** for UI.
- **SwiftData** for persistence (no Core Data directly).
- **Swift Concurrency** (`async`/`await`) only — **no Combine**.
- **Swift Testing** for unit tests, **XCUITest** for UI tests.
- Follow SOLID principles, Use Cases + Repository pattern, clean boundaries.
- Verbose camelCase naming — no abbreviations like “el” for element.
- Avoid force-unwraps.
- Accessibility identifiers on all user-interactive elements for test automation.

## Core Features
- Recipes:
  - Name (required).
  - Notes (optional).
  - Optional photo via `PhotosPicker`.
  - No ingredient list in current version.
- Photos:
  - Plan for Base64 thumbnail string (small JPEG) + original image stored locally by filename.
  - CloudKit sync in future will use Base64 thumbnail only.
- Menu generation:
  - Requires **≥ 7 recipes** before enabling.
  - User selects subset of days (Mon–Sun).
  - Increments `usageCount` for selected recipes.
  - Displays “not enough recipes” message if below threshold.

## Architecture Details
- `@Observable` view models (no Combine).
- Shared `@Observable AppState` in `.environment(appState)`:
  - Has `refreshCounter` that views watch with `.task(id:)` or `onChange` to refresh state after debug actions.
- Views:
  - `RecipesView`: shows list or empty state; Add button presents `AddRecipeView`.
  - `AddRecipeView`: form with recipeName, notes, photo picker.
  - `GenerateMenuView`: form with day toggles, requirement message, generate button, menu list.
  - `DebugMenuView`: buttons for seeding/clearing data.
- Menu rows: Render from snapshot values (day + recipe name), not live model objects, to avoid diffing crashes.

## File Structure
- Soruces folder contains the all the main source file.
  - Views folder contains all SwiftUI View files.
  - ViewModels folder contains all view models related to views.
  - Use Cases folder contains all use case used in view models.
  - Repositories folder contains all repositories used for store and fetching of data using SwiftData.
  - Models folder contains all models used by app.
  - Application folder contains main app file used to run the app and root of the application.
  - Debug Menu folder contains all debug related code used to debug the app at run time.
  - Supporting Files folder contains all relevant supporting files and folders such as asset catalog, info.plist ect.
  - TestPlans folder contains xctestplan files.
  - Tests UITests folders contain all test and ui test related files.

## Debug & Test Hooks
- Debug menu visible in debug builds or via launch arg `-debug-menu`.
- Debug actions:
  - Clear all data.
  - Seed N recipes.
  - Seed menu.
  - Reset usage counts.
  - Refresh views via `appState.bump()`.
- UITest modes via launch args:
  - `-ui-tests-blank`: empty store.
  - `-ui-tests-seeded`: ≥8 recipes (passes 7-min rule).
  - `-ui-tests-seeded-few`: <7 recipes.

## Accessibility IDs
**Recipes tab:**
- `recipesList`
- `emptyRecipesView`
- `addRecipeButton`

**Add recipe:**
- `recipeNameField`
- `notesField`
- `choosePhotoButton`
- `recipeImagePreview` (optional)
- `saveRecipeButton`

**Menu:**
- `toggleDay_<Mon|Tue|...>`
- `generateMenuButton`
- `menuRecipesRequirementMessage`
- `menuValidationMessage`
- `menuItem_<Day>`

**Debug menu:**
- `debug_button`
- `debug_clearAll`
- `debug_seedRecipes`
- `debug_seedMenu`
- `debug_resetUsage`
- `debug_refresh`
- `debug_info`

## Test Coverage (High-Level)
- UI:
  - Add/delete recipe.
  - Generate menu for selected days when seeded.
  - Block generate when <7 recipes.
- Unit:
  - AddRecipeViewModel save/reset.
  - GenerateMenuViewModel `canGenerate` logic.
  - Usage count increments after generation.

## Stability Notes
- Don’t mutate `generatedMenu` or `errorMessage` from `.task(id:)` while a `Form` is diffing.
- For async refresh (e.g., debug actions), reload counts or data via `loadAvailability()` and similar methods, then update UI.

