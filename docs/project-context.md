---
project_name: 'what-to-make'
user_name: 'Amish'
date: '2026-06-14'
sections_completed:
  - technology_stack
  - language_rules
  - framework_rules
  - testing_rules
  - quality_rules
  - workflow_rules
  - anti_patterns
status: complete
rule_count: 47
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

| Layer | Technology | Version / Notes |
|-------|-----------|-----------------|
| Platform | iOS | Deployment target **26.0** (app); project-level **17.0** |
| Language | Swift | **5.0** |
| UI | SwiftUI + Observation | `@Observable` view models, `@Bindable` in views |
| Persistence | SwiftData | Models: `Recipe`, `Menu` |
| Concurrency | Swift Concurrency | `async`/`await` only — **no Combine** |
| Unit tests | Swift Testing | `@Test`, `#expect`; import `@testable import ForkPlan` |
| UI tests | XCUITest | Launch-argument store modes |
| CI/CD | Fastlane + GitHub Actions | `macos-26` runners |
| Build | Xcode **26+** (local) | Workspace: `whattomake.xcworkspace`, scheme: `whattomake` |
| App product | `ForkPlan.app` | Differs from repo name `what-to-make` / `whattomake` |

**Open:** `whattomake.xcworkspace` (not `.xcodeproj` alone).

---

## Critical Implementation Rules

### Language-Specific Rules

- Use **Swift Concurrency only** — do not introduce Combine publishers, `@Published`, or Combine-based state.
- Mark view models, repository protocols, and use cases with **`@MainActor`** where existing code does.
- Repository and use case methods are **`async throws`** — propagate errors; do not swallow persistence failures silently (except UI-test seed helpers).
- **No force unwraps** (`!`) unless strongly justified and documented.
- Use **verbose camelCase** naming — no abbreviations like `el` for element.
- Write **DocC-style `///` comments** on public types and non-obvious methods; include `- Parameters:` blocks where helpful.
- Domain errors live in `Sources/UseCases/Errors/` (`RecipeError`, `MenuError`) — extend these rather than ad-hoc string errors in use cases.

### Framework-Specific Rules

**Architecture (Clean / Use Case + Repository):**

```
Views → ViewModels → UseCases → Repositories → SwiftData
```

- **Views** (`Sources/Views/`) — declarative UI only; minimal logic.
- **ViewModels** (`Sources/ViewModels/`) — `@Observable`, UI state, orchestration.
- **UseCases** (`Sources/UseCases/`) — application logic, validation, side effects.
- **Repositories** (`Sources/Repositories/`) — protocol + `SwiftData*` implementation; isolate persistence.
- **Models** (`Sources/Models/`) — SwiftData `@Model` types and image helpers.
- **DesignSystem** (`Sources/DesignSystem/`) — shared styling; use `fpAppTheme()`, `FpTypography`, `fpPrimary()`, etc.
- Wire dependencies at the **composition root** in `Sources/Application/WeeklyMenuApp.swift` — do not instantiate repositories inside views.

**SwiftUI patterns:**

- View models are **`@Observable`** — bind with `@Bindable var viewModel` in views.
- Menu list rows must render from **snapshot values** (day + recipe name tuples), not live `@Model` objects — prevents Form diffing crashes.
- Do not mutate `generatedMenu` or `errorMessage` from `.task(id:)` while a `Form` is diffing — reload via `loadAvailability()` or similar async methods instead.
- Use `.task { await vm.loadAvailability() }` for initial async loads; avoid fire-and-forget tasks that leave UI inconsistent.

**SwiftData / persistence:**

- Normal launches use a **persistent** `ModelContainer`; UI tests use **in-memory** stores via launch arguments.
- Recipe fields: `name` (required), `notes` (optional), `usageCount`, `thumbnailBase64`, `imageFilename`.
- Menu fields: `generatedDate`, `days`, `recipes` (snapshot of selected recipes).
- **No ingredient list** in the current product — do not reintroduce ingredient-related logic, identifiers, or tests.

**Image storage (split design — do not blur):**

- **Thumbnails:** Base64 JPEG string stored inline on `Recipe.thumbnailBase64` (via `ImageCodec`).
- **Originals:** Full-resolution files on disk via `ImageStore` at `Application Support/Images`; referenced by `imageFilename`.
- On delete, remove on-disk file best-effort; treat disk storage as local-only, not synced canonical data.

**Product rules:**

- Menu generation requires **≥ 7 recipes** (`minRecipesRequired = 7`).
- User selects any subset of days Mon–Sun.
- Generating a menu **increments `usageCount`** on selected recipes.
- Recipe `name` is required; `notes` and photos are optional.

### Testing Rules

**Unit tests (`Tests/`):**

- Framework: **Swift Testing** — `@Test` functions, `#expect`, `@MainActor` on test structs when testing main-actor VMs.
- Import: `@testable import ForkPlan` (module name, not repo name).
- Use **mock repositories** (`Tests/Mocks/MockRecipeRepository.swift`, `MockMenuRepository.swift`) — do not hit real SwiftData in unit tests.
- Test plan: `TestPlans/UnitTestsPlan.xctestplan` → target `whattomakeTests`.

**UI tests (`UITests/`):**

- Test plan: `TestPlans/UITestsPlan.xctestplan` → target `whattomakeUITests`.
- Base class: `UITestBase.swift`.
- Launch arguments control store mode:
  - `-ui-tests-blank` — empty in-memory store
  - `-ui-tests-seeded` — ≥ 8 recipes pre-seeded
  - `-debug-menu` — expose debug menu outside debug builds

**When behavior changes, update tests** — especially validation rules, menu generation, persistence, image handling, accessibility identifiers, and launch-argument behavior.

### Code Quality & Style Rules

- Follow **SOLID** and clean boundaries — keep orchestration out of views.
- Place new files in the existing folder structure under `Sources/`; match neighboring file header comments.
- **Accessibility identifiers** are part of the UI test contract — treat changes as breaking unless tests update in the same change.

**Required accessibility identifiers:**

| Area | Identifiers |
|------|------------|
| Recipes | `recipesList`, `emptyRecipesView`, `addRecipeButton` |
| Add recipe | `recipeNameField`, `notesField`, `choosePhotoButton`, `saveRecipeButton` |
| Menu | `toggleDay_<Day>`, `generateMenuButton`, `menuItem_<Day>`, `menuRecipesRequirementMessage`, `menuValidationMessage` |
| Debug | `debug_*` (e.g. `debug_clearAll`, `debug_seedRecipes`) |

- Add accessibility identifiers to **all user-interactive elements**.
- Ignore naming inconsistencies (`whattomake` vs `ForkPlan`) unless they cause build, import, or test failures.

### Development Workflow Rules

**Local setup:** macOS, Xcode 26+, iOS 26+ simulator. Open `whattomake.xcworkspace`. Run `bundle install` for Fastlane.

**Build & test commands:**

```bash
# Unit tests
xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# UI tests
xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UITestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# CI-equivalent via Fastlane
WORKSPACE="$PWD" WORKSPACE_FILENAME="whattomake.xcworkspace" \
SCHEME="whattomake" TEST_PLAN="UnitTestsPlan" \
bundle exec fastlane runUnitTests
```

**CI/release:** PR checks in `.github/workflows/pull-request.yml` (Conventional Commit title validation + unit tests via `fastlane runUnitTests` on `macos-26`, using the runner’s preinstalled Fastlane). Merged-branch workflow in `.github/workflows/merged.yml` runs [Oliver-Binns/Versioning](https://github.com/Oliver-Binns/Versioning) to create GitHub releases/tags from commit semantics; TestFlight deploy runs only when Versioning produces a new release (skips `chore`/`docs`/`ci`/etc. merges to save CI minutes). **Two version tracks:** GitHub release semver is automated; App Store `MARKETING_VERSION` is set manually in Xcode before release; Fastlane reads marketing version from the project and increments `CURRENT_PROJECT_VERSION` from the latest TestFlight build for that marketing version.

**Commits:** Conventional Commits enforced by `hooks/commit-msg`.

```
<type>[optional scope][optional !]: <description>
```

Allowed types: `build`, `ci`, `docs`, `fix`, `feat`, `chore`, `style`, `refactor`, `perf`, `test`. Scope is optional; prefer unscoped messages unless scope adds clarity (e.g. `fix(menu): handle empty state`).

**PR review priorities** (see `.github/copilot-instructions.md`):

1. Functional regressions
2. Data-loss / persistence risks
3. SwiftUI state / concurrency defects
4. Architecture boundary violations
5. Accessibility / UI test regressions
6. Missing tests for changed behavior

### Critical Don't-Miss Rules

**Do NOT:**

- Introduce **Combine** for state or async work.
- Put **business logic in SwiftUI views** — use view models and use cases.
- Bypass **repository/use case boundaries** or write SwiftData queries directly in views.
- Render menu rows from **live mutable `@Model` objects** — use snapshot tuples.
- Change **accessibility identifiers** without updating UI tests in the same change.
- Store full-resolution images **inline in SwiftData** — keep the thumbnail/original split.
- Reintroduce **ingredient list** features — out of scope for current version.
- Use **force unwraps** on persistence or image paths without fallback handling.
- Add production complexity **only to support tests** — use launch args and debug menu instead.

**Stability edge cases:**

- `GenerateMenuViewModel.generate()` wraps async work in `Task { @MainActor in ... }` — preserve main-actor isolation when extending.
- UI-test seed in `StoreFactory.seedIfNeeded` intentionally ignores save errors — do not copy this pattern to production code.
- `ImageStore` falls back to a temp `Images` directory if `Application Support` is unavailable — preserve this fallback.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code.
- Follow ALL rules exactly as documented.
- When in doubt, prefer the more restrictive option.
- Update this file if new patterns emerge.

**For Humans:**

- Keep this file lean and focused on agent needs.
- Update when technology stack changes.
- Review quarterly for outdated rules.
- Remove rules that become obvious over time.

Last Updated: 2026-06-14
