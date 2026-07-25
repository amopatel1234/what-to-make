# Architecture boundaries (agent guide)

Canonical product rules remain in [`project-context.md`](project-context.md). This page is the **shape** of the app: where code lives and which state wrappers are forbidden.

## Allowed layout under `Sources/`

| Folder | Role |
|--------|------|
| `Application/` | App entry (`WeeklyMenuApp`) — shared `ModelContainer` + App Intent dependency registration |
| `Views/` | SwiftUI views + thin `@Observable` coordinators (transient UI) |
| `Models/` | SwiftData `@Model` types + `ImageCodec` / `ImageStore` |
| `Helpers/` | Pure / testable logic (`MenuGenerator`, `MenuGeneration`, `DayDietConstraintStorage`, `MenuPersistence`, `MenuIntentSupport`, …) |
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
  → MenuGenerator.select (pure)
  → MenuPersistence.replaceMenu + usageCount
  → @Query updates UI
```

## App Intents

```
Siri / Shortcuts
  → Sources/Intents/* (thin AppIntent)
  → MenuIntentSupport + MenuGeneration (Helpers)
  → ForkPlanModelContainer.shared
```

Keep intent `perform()` thin. Put dialog formatting and UserDefaults reads in `Helpers/` so they stay unit-testable without invoking App Intents runtime.

See [`project-context.md`](project-context.md) for full product and testing contracts.
