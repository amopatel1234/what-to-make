# AGENT.md

## Project overview

`what-to-make` is an iOS app built with SwiftUI, SwiftData, and Swift Concurrency. The app lets users save recipes and generate a weekly menu from those saved recipes.

The codebase follows a clean architecture style:

- `Sources/Application`: app entry point, store bootstrapping, root navigation
- `Sources/Models`: SwiftData models plus image encoding/storage helpers
- `Sources/Repositories`: repository protocols and SwiftData-backed implementations
- `Sources/UseCases`: application logic
- `Sources/ViewModels`: `@Observable` UI state and orchestration
- `Sources/Views`: SwiftUI screens
- `Sources/DesignSystem`: shared UI styling and components
- `Tests`: unit tests using Swift Testing
- `UITests`: UI tests using XCUITest
- `TestPlans`: Xcode test plans for unit and UI test runs
- `fastlane`: CI/deployment automation
- `.github/workflows`: pull request and merged-branch automation
- `docs`: project site/docs content
- `context`: extra engineering context used to guide agents

## Local setup

Requirements:

- macOS with Xcode 15+ for local development
- iOS 17+ simulator/runtime
- Ruby/Bundler for Fastlane-based automation

Open the project with:

```bash
open whattomake.xcworkspace
```

Useful install/setup commands:

```bash
bundle install
bundle exec fastlane --version
```

Notes:

- The shared Xcode scheme is `whattomake`.
- The built app product in the shared scheme is currently `ForkPlan.app`, so do not assume the app bundle name matches the repository name.
- `fastlane/Fastfile` currently selects `/Applications/Xcode_16.4.app` explicitly in CI-oriented lanes.

## Build and test commands

Run unit tests with the dedicated test plan:

```bash
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

Run UI tests with the UI test plan:

```bash
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UITestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

Run the Fastlane unit-test lane used by CI:

```bash
WORKSPACE="$PWD" \
WORKSPACE_FILENAME="whattomake.xcworkspace" \
SCHEME="whattomake" \
TEST_PLAN="UnitTestsPlan" \
bundle exec fastlane runUnitTests
```

Important test/CI details:

- `TestPlans/UnitTestsPlan.xctestplan` runs `whattomakeTests`
- `TestPlans/UITestsPlan.xctestplan` runs `whattomakeUITests`
- PR workflow runs on `macos-15`
- PR workflow validates pull request naming and runs `fastlane runUnitTests`
- Merged-branch workflow handles versioning and TestFlight deployment

## Architecture and runtime behavior

Primary patterns and constraints:

- SwiftUI for UI
- SwiftData for persistence
- Swift Concurrency (`async`/`await`) only
- `@Observable` view models
- Use Cases + Repository pattern
- Avoid Combine
- Avoid force unwraps

Runtime store behavior from `Sources/Application/WeeklyMenuApp.swift`:

- Normal app launches use a persistent `ModelContainer`
- UI test launches can switch to in-memory stores via launch arguments
- `-ui-tests-blank` uses an in-memory empty store
- `-ui-tests-seeded` uses an in-memory seeded store

Current seeded UI-test mode inserts 8 recipes so the weekly menu flow satisfies the minimum recipe requirement.

## Data and storage

SwiftData models:

- `Sources/Models/Recipe.swift`
- `Sources/Models/Menu.swift`

Persisted recipe fields include:

- `name`
- `notes`
- `usageCount`
- `thumbnailBase64`
- `imageFilename`

Persisted menu fields include:

- `generatedDate`
- `days`
- `recipes`

Image storage behavior from `Sources/Models/ImageCodec.swift`:

- Thumbnail images are stored inline on the `Recipe` model as Base64 JPEG strings
- Original full-resolution images are stored on disk via `ImageStore`
- The on-disk image directory is the app container's `Application Support/Images`
- If `Application Support` is unavailable, image storage falls back to a temporary `Images` directory

When editing image-related features, preserve the split between:

- lightweight thumbnail data in SwiftData
- original image files on disk referenced by filename

## Project conventions

Code conventions already documented in the repo:

- Use SOLID principles and clean boundaries
- Keep views light and put orchestration in view models/use cases
- Use verbose camelCase naming
- Prefer DocC-style documentation comments for code docs
- Keep accessibility identifiers stable for UI tests

Feature constraints that show up across docs/tests:

- Recipe name is required
- Notes are optional
- Photos are optional
- There is no ingredient list in the current version
- Menu generation requires at least 7 recipes
- Users can select any subset of days from Mon-Sun
- Generating a menu increments `usageCount`
- Menu rows should render from snapshot values, not live mutable model objects

## Accessibility and test hooks

UI tests rely on accessibility identifiers such as:

- `recipesList`
- `emptyRecipesView`
- `addRecipeButton`
- `recipeNameField`
- `notesField`
- `choosePhotoButton`
- `saveRecipeButton`
- `toggleDay_<Day>`
- `generateMenuButton`
- `menuItem_<Day>`
- `menuRecipesRequirementMessage`
- `menuValidationMessage`
- `debug_*`

Debug/test launch behavior:

- `-debug-menu` enables the debug menu outside normal debug-only visibility
- Debug actions include clearing data, seeding data, resetting usage counts, and refreshing app state

## Automation and release flow

CI and release-related files:

- `.github/workflows/pull-request.yml`
- `.github/workflows/merged.yml`
- `fastlane/Fastfile`
- `sonar-project.properties`
- `scripts/xccov-to-sonarqube-generic.sh`

Important automation details:

- SonarCloud analysis is configured for `Sources` and `Tests`
- Fastlane `runUnitTests` generates an `.xcresult` bundle and converts coverage for SonarCloud
- Fastlane `deploy` increments the build number, updates the marketing version, builds the app, and uploads to TestFlight

## Commit and review guidance

The repo includes a `hooks/commit-msg` hook enforcing Conventional Commits. Use commit messages in this shape:

```text
docs: update AGENT.md
fix: correct menu validation logic
feat!: remove deprecated recipe flow
```

General format:

```text
<type>[optional scope][optional !]: <description>
```

Guidance:

- Keep the type lowercase
- Keep the description short and specific
- Use `!` immediately before `:` for a breaking change
- Use a `BREAKING CHANGE:` footer when extra detail is needed
- Scope is optional and should usually be omitted unless it adds useful clarity
- If you use scope, keep it to a short noun for a real area of the codebase, for example `fix(menu): handle empty state`

Allowed prefixes enforced by the hook:

- `docs`
- `fix`
- `feat`
- `chore`
- `style`
- `refactor`
- `perf`
- `test`

Meaning of the common types used in this repo:

- `feat`: a new user-facing or developer-facing feature
- `fix`: a bug fix
- `docs`: documentation-only changes
- `chore`: maintenance or project housekeeping that is not a feature/fix
- `style`: formatting or stylistic cleanup with no behavioral change
- `refactor`: code restructuring with no intended behavior change
- `perf`: a change intended to improve performance
- `test`: adding or updating tests

Practical advice:

- Prefer a single clear type over trying to encode everything in one commit
- If a change mixes unrelated concerns, split it into multiple commits when practical
- Most commits do not need scope
- Good examples: `fix: prevent duplicate seeded recipes`, `docs: clarify local setup`, `test: cover menu validation`
- Use scope sparingly: `feat(images): persist original photo filenames`

## Agent guidance for edits

Before making changes:

- Check whether the change affects `Sources`, `Tests`, `UITests`, or CI automation together
- Preserve repository pattern and use case boundaries
- Update or add tests when behavior changes
- Keep UI test identifiers intact unless the tests are updated at the same time

When working on persistence or images:

- Be careful not to break the persistent SwiftData model
- Preserve `ImageStore` file-location assumptions
- Treat on-disk images as best-effort local storage, not synced canonical data
