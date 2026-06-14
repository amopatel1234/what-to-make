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

**Extended source of truth:** `_bmad-output/planning-artifacts/architecture.md` documents refactor sequencing and ADRs. This file distills actionable rules only — do not duplicate epic/story prose here.

---

## Technology Stack & Versions

| Layer | Technology | Version / Notes |
|-------|-----------|-----------------|
| Platform | iOS | Deployment target **26.0** |
| Language | Swift | **6** (strict concurrency; per-target rollout) |
| UI | SwiftUI + Observation | `@Query`, `@Observable` coordinators, `@Bindable` |
| Persistence | SwiftData | `@Query` reads; `modelContext` writes |
| Concurrency | Swift Concurrency | `async`/`await` only — **no Combine** |
| Unit tests | Swift Testing | `@Test`, `#expect`; `@testable import ForkPlan` |
| Snapshot tests | swift-snapshot-testing | Point-Free; `whattomakeTests` target only |
| CI/CD | Fastlane + GitHub Actions | `macos-26` runners |
| Build | Xcode **26+** | `whattomake.xcworkspace`, scheme `whattomake` |
| App product | `ForkPlan.app` | Repo name `what-to-make` / `whattomake` |

**Open:** `whattomake.xcworkspace` (not `.xcodeproj` alone).

**Deferred (not implemented yet):** Usage-weighted menu selection (Phase 3 / Epic 3). Foundation Models integration (Phase 4).

---

## Critical Implementation Rules

### Language-Specific Rules

- Use **Swift 6** with **strict concurrency** — enable `SWIFT_STRICT_CONCURRENCY = complete` per-target; roll out models/tests first, main app target last.
- Use **Swift Concurrency only** — do not introduce Combine publishers, `@Published`, or Combine-based state.
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
- **Helpers** (`Sources/Helpers/`) — pure logic: `MenuGenerator`, `DaySelectionStorage`, `AppStorageKey`, `MenuPersistence`.
- **DesignSystem** (`Sources/DesignSystem/`) — shared styling; use `fpAppTheme()`, `FpTypography`, `fpPrimary()`, etc.
- **Application** (`Sources/Application/WeeklyMenuApp.swift`) — `.modelContainer` only; no use case or repository wiring.
- **Deleted after refactor:** `Sources/UseCases/`, `Sources/Repositories/`, `Sources/ViewModels/`.

**Data flow (generate menu):**

```
User action (view)
  → validate (≥ 7 recipes, ≥ 1 day)
  → MenuGenerator.select() [pure struct, no @MainActor]
  → increment usageCount on selected recipes
  → MenuPersistence.replaceMenu(with:in:) [delete-before-insert]
  → @Query auto-updates view
```

**State management:**

| Concern | Pattern |
|---------|---------|
| Recipe list | `@Query(sort: \Recipe.name)` |
| Latest menu | `@Query` via `Menu.latestDescriptor()` → `menus.first` |
| Day toggles | `@AppStorage` via `DaySelectionStorage` + `AppStorageKey` |
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
- Recipe fields: `name` (required), `notes` (optional), `usageCount`, `thumbnailBase64`, `imageFilename`.
- Menu fields: `generatedDate`, `days`, `recipes` (snapshot of selected recipes).
- **No ingredient list** in the current product — do not reintroduce ingredient-related logic, identifiers, or tests.
- Canonical day identifiers: `"Mon"` … `"Sun"` (locale-independent).

**Image storage (split design — do not blur):**

- **Thumbnails:** Base64 JPEG string stored inline on `Recipe.thumbnailBase64` (via `ImageCodec`).
- **Originals:** Full-resolution files on disk via `ImageStore` at `Application Support/Images`; referenced by `imageFilename`.
- On delete, remove on-disk file best-effort; treat disk storage as local-only, not synced canonical data.

**Product rules:**

- Menu generation requires **≥ 7 recipes** (`minRecipesRequired = 7`).
- User selects any subset of days Mon–Sun.
- Generating a menu **increments `usageCount`** on selected recipes.
- Recipe `name` is required; `notes` and photos are optional.

**Folder structure (target):**

```
Sources/
  Application/   WeeklyMenuApp.swift
  Views/         RecipesListView, AddRecipeView, GenerateMenuView
  Models/        Recipe, Menu, ImageCodec (ImageStore)
  Helpers/       MenuGenerator, DaySelectionStorage, AppStorageKey, MenuPersistence
  DesignSystem/  unchanged
Tests/
  Fixtures/      makeTestContainer() (Story 0.3)
  __Snapshots__/ iPhone17Pro-iOS26/ (Story 0.5+)
```

### Testing Rules

**Unit tests (`Tests/`):**

- Framework: **Swift Testing** — `@Test` functions, `#expect`, `@MainActor` on test structs when testing main-actor code.
- Import: `@testable import ForkPlan` (module name, not repo name).
- Use **`makeTestContainer()`** in `Tests/Fixtures/TestModelContainer.swift` — in-memory `ModelContainer`, direct seed; no launch arguments.
- Test plan: `TestPlans/UnitTestsPlan.xctestplan` → target `whattomakeTests`.
- Test target: `SWIFT_STRICT_CONCURRENCY = complete`.

**Snapshot tests (`Tests/`):**

- Library: Point-Free **swift-snapshot-testing** (`import SnapshotTesting`); linked to `whattomakeTests` only.
- Baselines: `Tests/__Snapshots__/iPhone17Pro-iOS26/` — light mode, fixed locale, standard Dynamic Type.
- Re-record locally only: `RECORD_SNAPSHOTS=1` — **never** in CI.
- Snapshot tests seed data directly via `makeTestContainer()` — no launch arguments.

**Removed (do not reintroduce):**

- `UITests/` target, `UITestsPlan.xctestplan`
- `Tests/Mocks/` mock repositories
- `-ui-tests-blank`, `-ui-tests-seeded`, `-debug-menu` launch arguments
- Use case / view model unit tests tied to deleted layers

**When behavior changes, update tests** — especially validation rules, menu generation, persistence, image handling, and snapshot baselines.

### Code Quality & Style Rules

- Keep business logic in **Helpers/** — not in view `body`.
- Place new files in the flat `Sources/` layout under `Views/`, `Models/`, `Helpers/`, or `DesignSystem/`; match neighboring file header comments.
- **Accessibility identifiers** support **VoiceOver continuity** (UX-DR9) — preserve on interactive elements; not an XCUITest contract.

**Required accessibility identifiers:**

| Area | Identifiers |
|------|------------|
| Recipes | `recipesList`, `emptyRecipesView`, `addRecipeButton` |
| Add recipe | `recipeNameField`, `notesField`, `choosePhotoButton`, `saveRecipeButton` |
| Menu | `toggleDay_<Day>`, `generateMenuButton`, `menuItem_<Day>`, `menuRecipesRequirementMessage`, `menuValidationMessage` |

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

# CI-equivalent via Fastlane
WORKSPACE="$PWD" WORKSPACE_FILENAME="whattomake.xcworkspace" \
SCHEME="whattomake" TEST_PLAN="UnitTestsPlan" \
bundle exec fastlane runUnitTests
```

**CI/release:** PR checks in `.github/workflows/pull-request.yml` (Conventional Commit title validation + unit tests via `fastlane runUnitTests` on `macos-26`, using the runner's preinstalled Fastlane). Merged-branch workflow in `.github/workflows/merged.yml` runs [Oliver-Binns/Versioning](https://github.com/Oliver-Binns/Versioning) to create GitHub releases/tags from commit semantics; TestFlight deploy runs only when Versioning produces a new release (skips `chore`/`docs`/`ci`/etc. merges to save CI minutes). **Two version tracks:** GitHub release semver is automated; App Store `MARKETING_VERSION` is set manually in Xcode before release; Fastlane reads marketing version from the project and increments `CURRENT_PROJECT_VERSION` from the latest TestFlight build for that marketing version.

**Commits:** Conventional Commits enforced by `hooks/commit-msg`.

```
<type>[optional scope][optional !]: <description>
```

Allowed types: `build`, `ci`, `docs`, `fix`, `feat`, `chore`, `style`, `refactor`, `perf`, `test`. Scope is optional; prefer unscoped messages unless scope adds clarity (e.g. `fix(menu): handle empty state`).

**PR review priorities** (see `.github/copilot-instructions.md` — **stale until Epic 2**; still describes legacy Clean Architecture):

1. Functional regressions
2. Data-loss / persistence risks
3. SwiftUI state / concurrency defects
4. Architecture boundary violations (reintroduced layers, logic in views)
5. Snapshot test / accessibility regressions
6. Missing tests for changed behavior

**Refactor approach:** Single batched release (NFR6) — no throwaway bug fixes in layers being deleted. Menu persistence fix: `@Query` + delete-before-insert via `MenuPersistence.replaceMenu(with:in:)`.

### Critical Don't-Miss Rules

**Do NOT:**

- Reintroduce use cases, repositories, ViewModels (beyond thin transient coordinators), or Combine
- Wire manual menu load paths — `@Query` replaces fetch wiring
- Use session-only `generatedMenu` without `@Query`
- Create mock repositories for tests — use `makeTestContainer()` instead
- Add XCUITest or `-ui-tests-*` launch arguments
- Put business logic in view `body` — extract to `MenuGenerator`, validation helpers
- Iterate live `@Model` `Recipe` in Form `ForEach` — use snapshot tuples
- Store full-resolution images inline in SwiftData — keep the thumbnail/original split
- Reintroduce ingredient list features — out of scope for current version
- Record snapshots in CI (`RECORD_SNAPSHOTS=1` local only)
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

Last Updated: 2026-06-15
