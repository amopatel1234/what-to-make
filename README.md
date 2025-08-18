# WeeklyMenu (what-to-make)

An iOS app that lets you save recipes and generate a randomized weekly menu. Built with SwiftUI, SwiftData, and Swift Concurrency using Clean Architecture (Use Cases + Repository pattern).

## Requirements
- iOS 17+
- Xcode 15+
- Swift Concurrency (async/await), SwiftUI, SwiftData

## Architecture
- Models (SwiftData): Recipe, Menu, lightweight image pipeline (thumbnailBase64 + on-disk original via ImageStore)
- Use Cases: Pure application logic (Add/Fetch/Count/Delete Recipes, Fetch Menus, Generate Menu)
- Repositories: Protocols + SwiftData implementations
- View Models: @Observable, UI-facing state and orchestration
- Views: SwiftUI screens, minimal logic; accessibility identifiers for UI tests

## Data model
- Recipe
  - name (required), notes (optional)
  - usageCount increments when included in a generated menu
  - thumbnailBase64 (Base64 JPEG for list rendering)
  - imageFilename (original image stored on disk via ImageStore)
- Menu
  - generatedDate (Date)
  - days: ordered day identifiers (e.g., ["Mon", "Tue"]) 
  - recipes: snapshot of selected Recipe models for those days

## Image pipeline
- User selects a photo via PhotosPicker.
- AddRecipeViewModel generates a small Base64 JPEG thumbnail and saves original to disk.
- Thumbnail and filename are persisted via AddRecipeUseCase; lists render from Base64 for performance and resilience.

## Use cases
- AddRecipeUseCase: validates and persists new Recipe; accepts optional thumbnailBase64 and imageFilename.
- FetchRecipesUseCase, FetchMenusUseCase: returns all items.
- CountRecipesUseCase: number of stored recipes.
- DeleteRecipeUseCase: deletes recipe and best-effort removes its original on-disk image.
- GenerateMenuUseCase: shuffles available recipes, picks N for selected days, increments usageCount, persists menu.

## View models
- RecipesListViewModel: loads and deletes recipes.
- AddRecipeViewModel: handles text fields, photo selection/preview, and save.
- GenerateMenuViewModel: enforces minimum recipe count (>= 7), validates selected days, calls GenerateMenuUseCase.

## Views
- RecipesListView: shows recipe name, optional notes, and a thumbnail if available; list id: recipesList
- AddRecipeView: fields for name/notes and photo picking; save persists optional image metadata
- GenerateMenuView: day toggles and generate action; renders snapshot rows using day + recipe name

## AppState
- @Observable AppState holds a refreshCounter to nudge views to reload after debug actions.
- Injected via environment.

## Debug Menu
Available in Debug builds or with the launch argument `-debug-menu`.
- Clear database
- Seed recipes and/or menus
- Reset usage counts
- Refresh AppState

## Accessibility identifiers (UI tests)
Ensure these IDs exist in UI:
- recipesList, emptyRecipesView, addRecipeButton
- recipeNameField, notesField, choosePhotoButton, saveRecipeButton
- toggleDay_<Day>, generateMenuButton, menuItem_<Day>
- menuRecipesRequirementMessage, menuValidationMessage
- debug_* (for debug actions)

## Project layout
```
Sources/
  Application/        App bootstrap and debug tools
  Models/             SwiftData models + ImageCodec/ImageStore
  Repositories/       Protocols + SwiftData-backed implementations
  UseCases/           Application logic
  ViewModels/         @Observable state for views
  Views/              SwiftUI screens
Tests/                Unit tests (Swift Testing)
UITests/              UI tests (XCUITest)
TestPlans/            UnitTestsPlan.xctestplan, UITestsPlan.xctestplan
```

## Build and run
Open the workspace in Xcode and run the app on iOS 17+.

Example commands (adjust scheme and destination for your setup):
```bash
# Unit tests via test plan
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test

# UI tests via test plan
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UITestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

## License
MIT. See [LICENSE](LICENSE).
