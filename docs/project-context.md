---
project_name: 'what-to-make'
user_name: 'Amish'
date: '2026-06-15'
sections_completed:
  - technology_stack
  - language_rules
  - framework_rules
  - testing_rules
  - quality_rules
  - workflow_rules
  - anti_patterns
status: complete
rule_count: 52
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

**Brownfield refactor:** This is an in-place architectural reset of `whattomake.xcworkspace` — not a greenfield project. Align existing code with the target SwiftUI-native patterns below.

---

## Technology Stack & Versions

| Layer | Technology | Version / Notes |
|-------|-----------|-----------------|
| Platform | iOS | Deployment target **26.0** |
| Language | Swift | **6.0** (language mode; strict concurrency `complete` on both targets) |
| UI | SwiftUI + Observation | `@Query`, `@Observable` coordinators, `@Bindable` |
| Persistence | SwiftData | `@Query` reads; `modelContext` writes |
| Concurrency | Swift Concurrency | `async`/`await` only — Observation / `@Observable`, not `@Published` / `@StateObject` / `@ObservedObject` |
| Unit tests | Swift Testing | `@Test`, `#expect`; `@testable import ForkPlan` |
| Snapshot tests | swift-snapshot-testing | Point-Free; `whattomakeTests` target only |
| CI/CD | Fastlane + GitHub Actions | `macos-26` runners |
| Build | Xcode **26+** | `whattomake.xcworkspace`, scheme `whattomake` |
| App product | `ForkPlan.app` | Repo name `what-to-make` / `whattomake` |

**Open:** `whattomake.xcworkspace` (not `.xcodeproj` alone).

**Deferred (not implemented yet):** Imperial/metric unit display conversion. Additional Foundation Models features beyond paste→recipe and suggest-missing-ingredients.

---

## Critical Implementation Rules

### Language-Specific Rules

- Use **Swift 6.0** with **`SWIFT_STRICT_CONCURRENCY = complete`** on both `whattomake` and `whattomakeTests` targets (Debug + Release).
- Use **Swift Concurrency only** — do not introduce `@Published`, `@StateObject`, or `@ObservedObject` (ObservableObject-style state). Prefer `@Observable` + `@Bindable`.
- Mark UI-touching code with **`@MainActor`** — views, coordinators, and persistence writes that touch the UI.
- Pure helpers (`MenuGenerator`, `DaySelectionStorage`) are **non-isolated value types** — do **not** put `@MainActor` on `MenuGenerator`.
- **No force unwraps** (`!`) unless strongly justified and documented.
- Use **verbose camelCase** naming — no abbreviations like `el` for element.
- Write **DocC-style `///` comments** on public types and non-obvious methods; include `- Parameters:` blocks where helpful.
- Validation errors: inline validation with user-visible messages in views/coordinators — not a separate domain error layer.

### Framework-Specific Rules

**Architecture (SwiftUI-native):**

```
Views (@Query + @State) → Models ← SwiftData
                         Helpers/ (pure logic)
                         DesignSystem/
```

- **Views** (`Sources/Views/`) — declarative UI; `@Query` for reads, `@Environment(\.modelContext)` for writes.
- **Models** (`Sources/Models/`) — SwiftData `@Model` types (`Recipe`, `Menu`) and image helpers (`ImageCodec`, `ImageStore`).
- **Helpers** (`Sources/Helpers/`) — pure logic: `MenuGenerator`, `DaySelectionStorage`, `DayDietConstraintStorage`, `AppStorageKey`, `MenuPersistence`.
- **DesignSystem** (`Sources/DesignSystem/`) — shared styling; use `fpAppTheme()`, `FpTypography`, `fpPrimary()`, etc. Screen intent, flows, and token tables: [`ux-design.md`](ux-design.md).
- **Application** (`Sources/Application/WeeklyMenuApp.swift`) — shared `ModelContainer`, App Intent dependency registration; no use case or repository wiring.
- **Deleted after refactor:** `Sources/UseCases/`, `Sources/Repositories/`, `Sources/ViewModels/`.

**Data flow (generate menu):**

```
User action (view)
  → validate (≥ 7 recipes, ≥ 1 day, diet pools) via MenuGeneration.validationMessage
  → map recipes → RecipeSelectionInput [Sendable snapshot]
  → MenuGenerator.select(from:requests:) [cook-recency weighted; pure struct, no @MainActor]
  → compactMap selected inputs back to Recipe by id
  → MenuGeneration.run → MenuPersistence.replaceMenu (cook stats unchanged)
  → @Query auto-updates view
```

Day tweak / cook tracking:

```
Menu day swipe → MenuGeneration.rerollDay / assignRecipe / markCooked
  → markCooked bumps usageCount + lastCookedAt only
```

**State management:**

| Concern | Pattern |
|---------|---------|
| Recipe list | `@Query(sort: \Recipe.name)` |
| Latest menu | `@Query` via `Menu.latestDescriptor()` → `menus.first` |
| Day toggles | `@AppStorage` via `DaySelectionStorage` + `AppStorageKey` |
| Day diet filters | `@AppStorage` via `DayDietConstraintStorage` + `AppStorageKey.dayDietConstraints` |
| Transient UI | `@State` or thin `@Observable` coordinator (transitional until Epic 1 ViewModel deletion) |
| Writes | `@Environment(\.modelContext)` in views / `MenuPersistence` |
| Async UI | `Task { @MainActor in ... }` |

**SwiftUI patterns:**

- `@Query` auto-loads data — do not wire manual fetch/load paths.
- Thin `@Observable` coordinators hold transient UI state only (validation messages, generation in-flight) — transitional until Epic 1 ViewModel deletion; do not add new ViewModels.
- Menu list rows must render from **snapshot value tuples** `(day: String, name: String)`, not live `@Model` objects — prevents Form diffing crashes.
- Map before `ForEach`: `Array(zip(menu.days, menu.recipes.map(\.name)))`.
- Dynamic `@Query` filters: use subview `init` with `_query = Query(...)` — never inline predicate on changing `@State`.
- Do not mutate persisted state from `.task(id:)` while a `Form` is diffing.

**SwiftData / persistence:**

- Normal launches use a **persistent** `ModelContainer` only — no launch-argument store modes.
- Menu lifecycle: **delete-before-insert** on regenerate — `MenuPersistence.replaceMenu(with:in:)` deletes all existing `Menu` records before inserting the new one.
- Latest menu: `@Query` via `Menu.latestDescriptor()` → display `menus.first`.
- Recipe fields: `name` (required), `notes` (optional), `usageCount` (times marked cooked), `lastCookedAt`, `thumbnailBase64`, `imageFilename`, `dietaryKindRaw` / `dietaryKind` (`standard` \| `vegetarian` \| `vegan`), `ingredients`.
- `RecipeIngredient` fields: `name` (required), `amount` (optional `Decimal`), `unit` (optional free text, stored as entered), `sortOrder`.
- Ingredient units are stored as-entered — no imperial/metric conversion in v1.
- Menu fields: `generatedDate`, `days`, `recipes` (snapshot of selected recipes).
- Canonical day identifiers: `"Mon"` … `"Sun"` (locale-independent).
- Per-day diet constraints: ``DayDietConstraint`` (`any` / `vegetarian` / `vegan`); vegan recipes satisfy vegetarian days; restricted days are hard filters (no fallback onto a veg/vegan day).
- Menu generation validates diet pools before select (enough vegan recipes for vegan days; enough vegetarian∪remaining vegan for veg days).
- Menu selection weights recipes by cook recency (`lastCookedAt`; never-cooked preferred). Planning a menu does **not** change cook stats.
- Day actions on an existing menu: re-roll one day, choose a library recipe, or mark that day’s recipe cooked.
- ``MenuGeneration/markCooked`` increments ``usageCount`` and sets ``lastCookedAt``.

**Image storage (split design — do not blur):**

- **Thumbnails:** Base64 JPEG string stored inline on `Recipe.thumbnailBase64` (via `ImageCodec`).
- **Originals:** Full-resolution files on disk via `ImageStore` at `Application Support/Images`; referenced by `imageFilename`.
- On delete, remove on-disk file best-effort; treat disk storage as local-only, not synced canonical data.

**Product rules:**

- Menu generation requires **≥ 7 recipes** (`minRecipesRequired = 7`).
- User selects any subset of days Mon–Sun; each selected day may be **Any**, **Veg**, or **Vegan**.
- Generating or tweaking a menu does **not** increment cook stats; only **Mark as cooked** does.
- Recipe `name` is required; `notes` and photos are optional.
- Recipe diet default is ``RecipeDietaryKind/standard``.

**Folder structure (target):**

```
Sources/
  Application/   WeeklyMenuApp.swift
  Views/         RecipesListView, AddRecipeView, GenerateMenuView
  Models/        Recipe, RecipeDietaryKind, RecipeIngredient, Menu, ImageCodec (ImageStore)
  Helpers/       MenuGenerator, MenuGeneration, DaySelectionStorage, DayDietConstraintStorage, AppStorageKey, MenuPersistence, MenuIntentSupport, ForkPlanModelContainer, AppleIntelligenceAvailability, RecipePasteExtraction, RecipeIngredientSuggestion, RecipeImagePlaygroundPrompt
  Intents/       GetTodaysMealIntent, GetWeeklyMenuIntent, GenerateWeeklyMenuIntent, ForkPlanShortcuts
  DesignSystem/  unchanged
Tests/
  Fixtures/      makeTestContainer() (Story 0.3)
  __Snapshots__/ iPhone17Pro-iOS26/ (see Tests/__Snapshots__/iPhone17Pro-iOS26/README.md)
```

**Apple Intelligence — paste recipe / suggest ingredients:**

- ``AppleIntelligenceAvailability`` (Helpers) maps ``SystemLanguageModel`` availability into ``available`` / ``notEnabled`` / ``unavailable`` for UI gating.
- ``RecipePasteExtractor`` (Helpers) uses Foundation Models guided generation (`@Generable`) to turn pasted text into ``RecipePasteDraft``.
- ``RecipeIngredientSuggestor`` suggests missing ingredients from recipe **name** (notes optional) plus existing lines; user must accept each suggestion. Empty results are a neutral status, not an error.
- Paste extraction is **Add Recipe only** (hidden while editing). Overwrite confirmation appears when the form already has content.
- ``AddRecipeCoordinator`` cancels overlapping extract/suggest tasks and clears in-flight work on sheet dismiss so stale results cannot land.
- ``AddRecipeCoordinator/applyPasteDraft`` / ``extractRecipeFromPaste`` / ``suggestMissingIngredients`` fill the form; user reviews then saves via existing SwiftData path.
- Amount parsing accepts ASCII and Unicode fractions (`1/2`, `½`, `1 1/2`) so pasted amounts are not dropped on save.
- **Unavailable** (ineligible / not ready / unknown): hide paste, suggest, and Image Playground UI. **Not enabled**: show controls disabled with Settings hint. Never auto-save generated drafts.
- Show ``RecipeIngredientSuggestor/generatedContentDisclaimer`` near AI controls so users always verify generated content.

**Apple Intelligence — Image Playground recipe photos:**

- ``RecipeImagePlaygroundPrompt`` (Helpers) builds version-agnostic concept text from name, ingredients, diet, and notes.
- ``RecipeImagePlaygroundSheetModifier`` (Views) presents iOS 26 `.imagePlaygroundSheet`; swap that file for iOS 27 API changes without rewriting Add Recipe.
- Do **not** use `ImageCreator` (removed in iOS 27). Gate the button with ``EnvironmentValues/supportsImagePlayground`` **and** ``AppleIntelligenceAvailability`` (hide when unavailable; disable + Settings hint when not enabled).
- Generated images reuse ``AddRecipeCoordinator/handleLoadedImageData`` (thumbnail + ``ImageStore``). User must still Save.

### Testing Rules

**Unit tests (`Tests/`):**

- Framework: **Swift Testing** — `@Test` functions, `#expect`, `@MainActor` on test structs when testing main-actor code.
- Import: `@testable import ForkPlan` (module name, not repo name).
- Use **`makeTestContainer()`** in `Tests/Fixtures/TestModelContainer.swift` — in-memory `ModelContainer`, direct seed; no launch arguments.
- Image disk tests may set ``ImageStore/directoryOverride`` to a temp directory and clear it in `defer`.
- Test plan: `TestPlans/UnitTestsPlan.xctestplan` → target `whattomakeTests`.
- Test target: `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete` (same as app target).

**Snapshot tests (`Tests/`):**

- Library: Point-Free **swift-snapshot-testing** (`import SnapshotTesting`); linked to `whattomakeTests` only.
- Baselines: `Tests/__Snapshots__/iPhone17Pro-iOS26/` — see [`Tests/__Snapshots__/iPhone17Pro-iOS26/README.md`](../Tests/__Snapshots__/iPhone17Pro-iOS26/README.md) for slug convention and recording workflow.
- Re-record baselines on a Mac via scheme env `RECORD_SNAPSHOTS=1`, or use the manual GitHub Action **Record Snapshot Baselines** (`workflow_dispatch` + `ALLOW_CI_SNAPSHOT_RECORD=1`) — never enable recording in the normal PR compare workflow.
- Shell `RECORD_SNAPSHOTS=1 xcodebuild …` often does not reach `TEST_HOST` (`ForkPlan.app`); use Xcode scheme Test env vars, test-plan env, or the record-snapshots workflow (see snapshot README).
- Snapshot tests seed data directly via `makeTestContainer()` — no launch arguments.
- CI runs snapshot **compare** on `macos-26` via `fastlane runUnitTests`; compare uses documented `precision: 0.98` / `perceptualPrecision: 0.98` to tolerate dev-Mac vs runner drift until baselines are re-recorded on `macos-26` (see snapshot README → CI compare mode).

**Device slug mapping:**

| Simulator destination | Device slug folder |
|-----------------------|-------------------|
| `platform=iOS Simulator,name=iPhone 17 Pro` | `Tests/__Snapshots__/iPhone17Pro-iOS26/` |

**Baseline recording settings** (Epic 2 snapshot tests must apply):

| Setting | Required value | Notes |
|---------|----------------|-------|
| Color scheme | Light | `.preferredColorScheme(.light)` or `@Environment(\.colorScheme)` override in test host |
| Locale | `en_US` | Set via test `Locale` environment or view modifier — pick one approach and document for Epic 2 |
| Dynamic Type | Standard (`.large` / default) | Do not use accessibility sizes in baseline snapshots |
| Simulator | iPhone 17 Pro | Must match CI Fastfile destination |

**Removed (do not reintroduce):**

- `UITests/` target, `UITestsPlan.xctestplan`
- `Tests/Mocks/` mock repositories
- `-ui-tests-blank`, `-ui-tests-seeded`, `-debug-menu` launch arguments
- Use case / view model unit tests tied to deleted layers

**When behavior changes, update tests** — especially validation rules, menu generation, persistence, image handling, and snapshot baselines.

### Code Quality & Style Rules

- Keep business logic in **Helpers/** — not in view `body`.
- Place new files in the flat `Sources/` layout under `Views/`, `Models/`, `Helpers/`, or `DesignSystem/`; match neighboring file header comments.
- **Accessibility identifiers** support **VoiceOver continuity** (UX-DR9) — preserve on interactive elements; not an XCUITest contract. Full UX principles: [`ux-design.md`](ux-design.md).

**Required accessibility identifiers:**

| Area | Identifiers |
|------|------------|
| Recipes | `recipesList`, `emptyRecipesView`, `addRecipeButton` |
| Add recipe | `recipeNameField`, `notesField`, `choosePhotoButton`, `generateRecipeImageButton`, `saveRecipeButton`, `recipeDietaryKindPicker`, `ingredientNameField_<index>`, `ingredientAmountField_<index>`, `ingredientUnitField_<index>`, `addIngredientButton`, `pasteRecipeField`, `extractRecipeButton`, `suggestIngredientsButton` |
| Menu | `toggleDay_<Day>`, `dayDiet_<Day>`, `generateMenuButton`, `menuItem_<Day>`, `menuRecipesRequirementMessage`, `menuValidationMessage`, `rerollDay_<Day>`, `chooseRecipeDay_<Day>`, `markCookedDay_<Day>` |

- Add accessibility identifiers to **all user-interactive elements**.
- Ignore naming inconsistencies (`whattomake` vs `ForkPlan`) unless they cause build, import, or test failures.

### Development Workflow Rules

**Local setup:** macOS, Xcode 26+, iOS 26+ simulator (pinned: **iPhone 17 Pro**). Open `whattomake.xcworkspace`. Run `bundle install` for Fastlane.

**Build & test commands:**

```bash
# Unit + snapshot tests (pinned simulator)
xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Re-record snapshot baselines (local only — never CI)
RECORD_SNAPSHOTS=1 xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# CI-equivalent via Fastlane (pinned iPhone 17 Pro via PINNED_TEST_DESTINATION in Fastfile)
WORKSPACE="$PWD" WORKSPACE_FILENAME="whattomake.xcworkspace" \
SCHEME="whattomake" TEST_PLAN="UnitTestsPlan" \
bundle exec fastlane runUnitTests
```

**CI/release:** PR checks in `.github/workflows/pull-request.yml` (Conventional Commit title validation + unit **and snapshot** tests via `fastlane runUnitTests` on `macos-26`, using the runner's preinstalled Fastlane). Snapshot compare runs on the pinned **iPhone 17 Pro** simulator — not skipped on CI. The `runUnitTests` lane pins the test destination via `PINNED_TEST_DESTINATION` in `fastlane/Fastfile`. Merged-branch workflow in `.github/workflows/merged.yml` runs [Oliver-Binns/Versioning](https://github.com/Oliver-Binns/Versioning) to create GitHub releases/tags from commit semantics; TestFlight deploy runs only when Versioning produces a new release (skips `chore`/`docs`/`ci`/etc. merges to save CI minutes). **Two version tracks:** GitHub release semver is automated; App Store `MARKETING_VERSION` is set manually in Xcode before release; Fastlane reads marketing version from the project and increments `CURRENT_PROJECT_VERSION` from the latest TestFlight build for that marketing version.

**Commits:** Conventional Commits enforced by `hooks/commit-msg`.

```
<type>[optional scope][optional !]: <description>
```

Allowed types: `build`, `ci`, `docs`, `fix`, `feat`, `chore`, `style`, `refactor`, `perf`, `test`. Scope is optional; prefer unscoped messages unless scope adds clarity (e.g. `fix(menu): handle empty state`).

**Architecture sensor (agent harness):** `./scripts/check-architecture.sh` — runs locally via `hooks/pre-push` (when `core.hooksPath` is set) and on every PR (including drafts) in the `harness` CI job. Full simulator tests still run only when the PR is ready for review. Boundaries and wrappers: [`architecture.md`](architecture.md). Recovery: [`agent-playbook.md`](agent-playbook.md). Steering log: [`harness-log.md`](harness-log.md).

**PR descriptions:** Short prose only — 2–3 paragraphs summarizing what changed and why. Do **not** include a test plan, checklist, or `## Summary` / `## Test plan` sections; CI runs tests automatically.

**PR review priorities:**

1. Functional regressions
2. Data-loss / persistence risks
3. SwiftUI state / concurrency defects
4. Architecture boundary violations (reintroduced layers, logic in views)
5. Snapshot test / accessibility regressions
6. Missing tests for changed behavior

**Refactor approach:** Single batched release (NFR6) — no throwaway bug fixes in layers being deleted. Menu persistence fix: `@Query` + delete-before-insert via `MenuPersistence.replaceMenu(with:in:)`.

### Critical Don't-Miss Rules

**Do NOT:**

- Reintroduce use cases, repositories, ViewModels (beyond thin transient coordinators), or `@Published` / `@StateObject` / `@ObservedObject`
- Wire manual menu load paths — `@Query` replaces fetch wiring
- Use session-only `generatedMenu` without `@Query`
- Create mock repositories for tests — use `makeTestContainer()` instead
- Add XCUITest or `-ui-tests-*` launch arguments
- Put business logic in view `body` — extract to `MenuGenerator`, validation helpers
- Iterate live `@Model` `Recipe` in Form `ForEach` — use snapshot tuples
- Store full-resolution images inline in SwiftData — keep the thumbnail/original split
- Record snapshots in the normal PR/CI compare lane (`RECORD_SNAPSHOTS=1` only via local scheme/test-plan or the manual `record-snapshots` workflow)
- Put `@MainActor` on `MenuGenerator`
- Scatter raw `@AppStorage` string keys — use `AppStorageKey` enum
- Use `recipes.shuffle()` without weighting (Phase 3 deferred)

**Stability edge cases:**

- Async UI work uses `Task { @MainActor in ... }` — preserve main-actor isolation when extending.
- `ImageStore` falls back to a temp `Images` directory if `Application Support` is unavailable — preserve this fallback.
- On menu save failure: `do/catch` → user-visible error message (never silent).

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

Last Updated: 2026-07-25
