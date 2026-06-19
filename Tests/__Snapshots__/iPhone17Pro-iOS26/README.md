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

Re-record on the pinned **iPhone 17 Pro** simulator after UI changes.

### TEST_HOST environment caveat

Shell `RECORD_SNAPSHOTS=1 xcodebuild …` often **does not** propagate into `TEST_HOST` (`ForkPlan.app`). Reliable options:

1. **Xcode scheme (recommended):** Edit Scheme → Test → Arguments → Environment Variables → `RECORD_SNAPSHOTS=1`
2. **Test plan env (optional):** Add `RECORD_SNAPSHOTS=1` to `TestPlans/UnitTestsPlan.xctestplan` locally — never commit with recording enabled for CI workflows
3. **First-time baselines:** Use `.missing` record mode; Swift Testing may report a failure once even though the PNG was written

```bash
# May not reach TEST_HOST — prefer Xcode scheme env vars
RECORD_SNAPSHOTS=1 xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

### `.missing` first-record behavior

When no reference PNG exists, swift-snapshot-testing writes the file but Swift Testing may still report a test issue on the first run. Re-run without record mode to confirm compare passes.

## Baseline settings

| Setting | Required value |
|---------|----------------|
| Color scheme | Light |
| Locale | `en_US` |
| Dynamic Type | Standard (default / `.large`) |
| Simulator | iPhone 17 Pro |
| Layout | Fixed 402×874 |

## CI compare mode

PR checks on `macos-26` run snapshot **compare** (not record) via `fastlane runUnitTests` and `UnitTestsPlan`.

- Baselines must be recorded on the same runner class as CI (`macos-26`) or replaced after analyzing CI failure attachments from `.xcresult`
- Never set `RECORD_SNAPSHOTS=1` in `.github/workflows/pull-request.yml` or `merged.yml`
- One-off runner re-record (if needed): separate `workflow_dispatch` with `RECORD_SNAPSHOTS=1` **and** `ALLOW_CI_SNAPSHOT_RECORD=1` — not merged into PR workflows
- `SnapshotTestConfiguration.isCI` blocks recording on CI unless `ALLOW_CI_SNAPSHOT_RECORD=1` is set

If CI compare fails after a UI change, download failure attachments from the PR workflow `test-results` artifact (`.xcresult`) or verify dimensions (402×874) and commit updated PNGs.

Compare uses `precision: 0.98` and `perceptualPrecision: 0.98` in `SnapshotTestConfiguration` to tolerate minor macos-26 vs dev Mac rendering drift until baselines are re-recorded on the runner.

See `docs/project-context.md` → Testing Rules → Snapshot tests for full workflow documentation.
