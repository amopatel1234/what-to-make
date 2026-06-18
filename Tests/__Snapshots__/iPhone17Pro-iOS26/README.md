# Snapshot baselines — iPhone17Pro-iOS26

Committed reference PNGs for visual regression testing (Epic 2+).

## Device slug convention

`iPhone17Pro-iOS26` = **iPhone 17 Pro** simulator + **iOS 26** deployment/runtime (spaces removed, hyphen-separated).

## Current status

Four reference PNGs committed for Epic 2 Story 2.1:

| File | Screen |
|------|--------|
| `emptyRecipesList.recipes-empty.png` | Empty recipe list |
| `recipesListWithData.recipes-with-data.png` | Recipe list with seeded data |
| `emptyMenuState.menu-empty.png` | Generate menu — empty state |
| `generatedMenuState.menu-generated.png` | Generate menu — generated Mon/Wed/Fri |

On-disk pattern: `{testFunctionName}.{named}.png` (flat folder, custom `snapshotDirectory`).

Do not commit ad-hoc PNGs outside this workflow.

## Recording baselines (local only)

Re-record on the pinned **iPhone 17 Pro** simulator after UI changes:

```bash
RECORD_SNAPSHOTS=1 xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Baseline settings

| Setting | Required value |
|---------|----------------|
| Color scheme | Light |
| Locale | `en_US` |
| Dynamic Type | Standard (default / `.large`) |
| Simulator | iPhone 17 Pro |

## CI

Never set `RECORD_SNAPSHOTS=1` in GitHub Actions. **Compare mode on CI is deferred to Story 2.2** — baselines are recorded locally on iPhone 17 Pro; the `macos-26` runner renders differently, so `SnapshotTestConfiguration` skips snapshot assertions when `GITHUB_ACTIONS` or `CI` is set. Unit tests still run on CI; snapshot compare runs locally before merge.

See `docs/project-context.md` → Testing Rules → Snapshot tests for full workflow documentation.
