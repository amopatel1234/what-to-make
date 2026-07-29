# Architecture boundaries (agent guide)

Canonical product rules remain in [`project-context.md`](project-context.md). Screen intent, flows, and visual tokens are in [`ux-design.md`](ux-design.md). This page is the **shape** of the app: where code lives and which state wrappers are forbidden.

## Allowed layout under `Sources/`

| Folder | Role |
|--------|------|
| `Application/` | App entry (`WeeklyMenuApp`) — shared `ModelContainer` + App Intent dependency registration |
| `Views/` | SwiftUI views + thin `@Observable` coordinators (transient UI) |
| `Models/` | SwiftData `@Model` types + `ImageCodec` / `ImageStore` |
| `Helpers/` | Pure / testable logic (`MenuGenerator`, `MenuGeneration`, `DayDietConstraintStorage`, `MenuPersistence`, `MenuIntentSupport`, `AppleIntelligenceAvailability`, `RecipePasteExtraction`, `RecipeIngredientSuggestion`, …) |
| `Intents/` | App Intents + `AppShortcutsProvider` (thin; call Helpers for work) |
| `DesignSystem/` | Shared `fp*` styling |

Do **not** add new top-level folders under `Sources/` without updating this doc and the architecture sensor if needed.

## Deleted layers (do not reintroduce)

These directories must not exist:

- `Sources/UseCases/`
- `Sources/Repositories/`
- `Sources/ViewModels/`

Enforced by `./scripts/check-architecture.sh`.

## State & concurrency wrappers

**Allowed (typical):** `@Observable`, `@Bindable`, `@State`, `@Query`, `@AppStorage`, `@Environment`, `@MainActor`.

**Forbidden under `Sources/`:**

| Wrapper | Why |
|---------|-----|
| `@Published` | Combine / `ObservableObject` state |
| `@StateObject` | Usually owns an `ObservableObject` ViewModel |
| `@ObservedObject` | Usually injects an `ObservableObject` ViewModel |

Prefer Observation + thin coordinators. Enforced by `./scripts/check-architecture.sh`.

## Data-flow sketch (menu generate)

```
View action
  → MenuGeneration.validationMessage / MenuGeneration.run
  → MenuGenerator.select (cook-recency weighted, pure)
  → MenuPersistence.replaceMenu (cook stats unchanged)
  → @Query updates UI
```

Day tweak / mark cooked:

```
Menu or Recipes swipe
  → MenuGeneration.rerollDay / assignRecipe / markCooked
  → markCooked updates usageCount + lastCookedAt
```

## App Intents

```
Siri / Shortcuts
  → Sources/Intents/* (thin AppIntent, @Dependency ModelContainer)
  → MenuIntentSupport + MenuGeneration (Helpers)
  → same ModelContainer as WeeklyMenuApp
```

Keep intent `perform()` thin. Put dialog formatting and UserDefaults reads in `Helpers/` so they stay unit-testable without invoking App Intents runtime.

- Register the container with `AppDependencyManager` in `WeeklyMenuApp` (`key: "ModelContainer"`); intents resolve it via `@Dependency`.
- Destructive intents (generate/replace menu) must `requestConfirmation` before writing.
- Validation failures should `throw` (e.g. `MenuIntentError`) so Shortcuts can treat them as failures.

See [`project-context.md`](project-context.md) for full product and testing contracts.

## Foundation Models (paste → recipe / suggest ingredients)

```
Add Recipe only (not Edit)
  → paste field → confirm if form already filled
  → RecipePasteExtractor.extract (Foundation Models + @Generable)
  → RecipePasteDraft
  → AddRecipeCoordinator.applyPasteDraft
  → user reviews → existing save

Add/Edit Recipe (name required; notes optional)
  → RecipeIngredientSuggestor.suggest
  → pending suggestions → user accepts into IngredientDrafts
    (empty → neutral status, not error)
  → existing save
```

Keep guided schemas and mapping in `Helpers/`. Do not persist until the user taps Save. Cancel overlapping AI tasks (and on dismiss). Always surface a check-generated-content disclaimer near AI controls.

Gate AI UI with `AppleIntelligenceAvailability`: **unavailable** hides paste / suggest / Image Playground; **notEnabled** keeps them visible but disabled with a Settings hint.

## Image Playground (recipe photos)

```
Add/Edit Recipe (name required)
  → RecipeImagePlaygroundPrompt (version-agnostic concepts)
  → RecipeImagePlaygroundSheetModifier (.imagePlaygroundSheet, iOS 26)
  → image Data → AddRecipeCoordinator.handleLoadedImageData
  → user Saves
```

Swap only the presenter/modifier for iOS 27 sheet/options changes. Never add `ImageCreator`.

