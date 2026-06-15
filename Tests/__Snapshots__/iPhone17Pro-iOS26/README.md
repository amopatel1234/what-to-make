# Snapshot baselines — iPhone17Pro-iOS26

Committed reference PNGs for visual regression testing (Epic 2+).

## Device slug convention

`iPhone17Pro-iOS26` = **iPhone 17 Pro** simulator + **iOS 26** deployment/runtime (spaces removed, hyphen-separated).

## Current status

No PNG baselines yet. Reference images will be recorded in Epic 2 Story 2.1 (`RecipeSnapshotTests`, `MenuSnapshotTests`).

Do not commit ad-hoc PNGs outside the Epic 2 snapshot workflow.

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

Never set `RECORD_SNAPSHOTS=1` in GitHub Actions. CI runs snapshot tests in compare-only mode on the pinned simulator.

See `docs/project-context.md` → Testing Rules → Snapshot tests for full workflow documentation.
