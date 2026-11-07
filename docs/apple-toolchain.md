# Apple toolchain and platform policy

ForkPlan supports the current major iOS release from launch. The minimum is
**iOS 27.0** across the project, app and test configurations. Future annual
upgrades deliberately raise that minimum after checking SDK and CI availability.
New features do not need iOS 26 compatibility paths. Device/model availability
checks for Apple Intelligence remain necessary. Other Apple platforms have
their own policies to be established in #80; their version numbers are not inferred
from iOS.

## Verified CI configuration

Checked against GitHub's published inventory on **2026-11-07**:

- [Available runner images](https://github.com/actions/runner-images#available-images)
  lists `xcode-27` (arm64, currently public preview).
- [Xcode 27 image inventory](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)
  lists `/Applications/Xcode_27.app` (Xcode 27.0), the iOS 27.0 SDK and
  **iPhone 17 on iOS 27.0**. This is the test/snapshot destination.
- The `macos-26` image lists Xcode 26, so it is insufficient for this minimum.

All Apple workflows select the same toolchain with
`DEVELOPER_DIR=/Applications/Xcode_27.app/Contents/Developer`; they do not follow
the image's changing default Xcode. Ruby setup installs Bundler 2.6.9 and the
committed `Gemfile.lock` dependencies, then runs `bundle exec fastlane`.
There is no dependency on a preinstalled Fastlane or a hardcoded Homebrew path.

Fastlane checks the selected Xcode major and both iOS SDKs before tests or
deployment signing work. Tests also require the exact available simulator.
Failures report what is missing; no device fallback, runtime download or
unreviewed snapshot recording happens in ordinary CI. Build-settings queries
use a 30-second base timeout with four retries for cold runners.

When the runner inventory changes, verify the linked inventory before changing
labels, application paths or destinations. Update all Apple workflows and the
snapshot configuration together. A runner's host OS does not establish its
installed SDKs or simulator inventory.

## Snapshot transition

Tests now compare against `Tests/__Snapshots__/iPhone17-iOS27/`. The existing
`iPhone17Pro-iOS26` PNGs are historical references, not valid iOS 27 baselines.
Four new PNGs were recorded on the selected Xcode 27.0 / iOS 27.0 destination
on 2026-11-07, visually inspected, and verified in a follow-up compare run
(137 tests, zero failures). For later UI changes, use the manual **Record Snapshot
Baselines** workflow, inspect the images and rerun ordinary compare mode. Missing references must fail until reviewed baselines exist. Do not rename
old PNGs or weaken comparison to make this transition pass.

## Upgrade validation and distribution

This change raises the OS minimum without changing the SwiftData schema, store
location or image format. Data compatibility remains required even though OS
backwards compatibility is dropped. Before shipping, install the previous app
on a device with populated recipes, ingredients, photos, cook history and an
active menu. Upgrade the OS to iOS 27 and update the app without deleting it;
confirm the data survives, then edit a recipe and regenerate a menu. Also check
App Intents, PhotosUI, Foundation Models and Image Playground on supported
hardware. Linux/static checks cannot establish that this walkthrough passed.

Devices remaining on iOS 26 cannot install this update. Keep their existing
data intact; do not reset stores to work around an upgrade failure. App Store
marketing versions and GitHub release versions remain separate. The new minimum
does not by itself establish TestFlight or App Store delivery.

## Agent validation loop

### Required validation before handoff

Agents **must use Apple validation** for changes to Swift/iOS code, tests, Xcode
project/workspace settings, dependencies, Fastlane or Apple workflows. Linux
architecture and configuration checks remain required but do not substitute for
Apple compilation and simulator tests.

1. Finish the implementation, run applicable Linux checks, and push the feature
   branch. Use an existing automatic run when it provides the required coverage;
   otherwise dispatch the workflow. No additional confirmation is needed when
   branch push and validation are already authorized in the task.
2. Use `buildForTesting` for intermediate compiler feedback and compile-only
   build/toolchain changes. Use `runUnitTests` for behavior, persistence, UI or
   test changes, and before marking implementation ready for review. A draft PR's
   automatic build does not satisfy the full-test requirement; dispatch full
   tests without changing PR status.
3. Wait for completion and inspect the outcome, test counts, failures and relevant
   logs/artifacts. Fix failures and repeat. Never replace snapshot references just
   to turn a failing comparison green; deliberate UI/baseline updates require
   separate recording, visual inspection and a recording-disabled compare run.
4. Match the evidence to the implementation being handed off. Check the actual
   checkout SHA; a PR run may test a synthetic merge commit, in which case verify
   its head/base relationship. New implementation, dependency or validation
   configuration changes invalidate earlier evidence and require the applicable
   check again. Documentation-only follow-ups do not invalidate that evidence.
5. In the final handoff, include the tested SHA, run link, lane and result. State
   remaining real-device checks separately. If authorization, credentials, runner
   access or another dependency blocks validation, complete independent work and
   report the specific blocker and outstanding checks; do not claim the iOS work
   is validated or treat an old run as current evidence.

Documentation-only edits require no additional Mac run when implementation and
validation configuration are unchanged. Avoid duplicate runs for an unchanged
implementation when a matching successful run already supplies the required
coverage. Validation does not authorize merging, releasing or deploying.

`bundle exec fastlane buildForTesting` compiles the app and test targets for the
pinned simulator with signing disabled, without executing tests or changing
snapshot baselines. `runUnitTests` executes unit and snapshot comparison tests.
Draft PRs run build-only validation; ready PRs run full tests through the same
reusable `Apple validation` workflow. Actions → Apple validation also accepts a
branch and the appropriate validation lane. Before merging, agents can dispatch the registered
workflow against this branch using the GitHub CLI.

Validation checks out the exact triggering SHA. Inspect the run summary and
`apple-validation-<SHA>-<lane>` artifact for environment inventory, compiler logs,
and result bundles. It has read-only repository permissions, a 30-minute timeout,
no signing secrets and no release/deployment steps. Linux agents should push a
feature branch, inspect runs for that SHA, fix errors and repeat. A successful
build-only run does not mean tests or real-device checks passed.

```bash
validation_branch="$(git branch --show-current)"
gh workflow run apple-validation.yml --repo amopatel1234/what-to-make \
  --ref "$validation_branch" -f lane=buildForTesting
# Use -f lane=runUnitTests for unit and snapshot tests.
gh run list --repo amopatel1234/what-to-make \
  --workflow apple-validation.yml --branch "$validation_branch"
```

Inspect the run's `head_sha` before accepting its result; branch names can move
while a run is active. Prefer the connected GitHub tools for job logs and artifact downloads in the
cloud environment. Direct `gh run download` can be blocked at the redirected
artifact-storage host even when GitHub access works; the connected artifact tool
was verified to work. On an unrestricted machine, `gh run download <run-id>`
is also available.

## First verified run (2026-11-07)

The draft build and on-demand dispatch both ran successfully on the verified
runner. The first full run exposed four missing snapshot references, with the
other 133 tests passing. The dedicated recording workflow created four iOS 27
references and its recording-disabled comparison passed all 137 tests:
[recording and comparison run](https://github.com/amopatel1234/what-to-make/actions/runs/42384835325).
The first cold simulator startup was slow and logged a device-service timeout;
build-only validation completed much sooner. Existing compiler concurrency
warnings remain visible in the artifacts. Real-device data-upgrade and Apple
Intelligence validation remain separate release checks.

## Release-workflow validation

Dispatch `merged.yml` with `validate_only=true` (the default) to exercise the
release workflow's reusable Mac validation job on a feature branch. The
`validateRelease` lane checks the toolchain and builds the app in Release
configuration for `generic/platform=iOS` using the device SDK with signing
disabled. It saves a result bundle and compiler output with one-day retention.
This does not execute versioning, create releases, use signing credentials,
archive/export an IPA or upload to TestFlight. Actual publishing remains a
separate path restricted to `main`; a successful unsigned build does not validate
signing, provisioning, App Store Connect credentials or upload permissions.

Snapshot recording may legitimately produce identical PNGs. After the separate
recording-disabled comparison succeeds, this no-change case is successful and
creates no baseline commit. Differing images still require visual inspection.
