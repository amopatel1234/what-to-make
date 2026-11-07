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
Record new PNGs on the selected Xcode 27.0 / iOS 27.0 destination using the manual
**Record Snapshot Baselines** workflow, inspect them and rerun ordinary compare
mode. Missing references must fail until reviewed baselines exist. Do not rename
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

`bundle exec fastlane buildForTesting` compiles the app and test targets for the
pinned simulator with signing disabled, without executing tests or changing
snapshot baselines. `runUnitTests` executes unit and snapshot comparison tests.
Draft PRs run build-only validation; ready PRs run full tests through the same
reusable `Apple validation` workflow. Actions → Apple validation also accepts a
branch and either lane once the workflow is available on the default branch.
A branch-specific push trigger bootstraps validation on `codex/ios27-validation`
before merging the workflow.

Validation checks out the exact triggering SHA. Inspect the run summary and
`apple-validation-<SHA>-<lane>` artifact for environment inventory, compiler logs,
and result bundles. It has read-only repository permissions, a 30-minute timeout,
no signing secrets and no release/deployment steps. Linux agents should push a
feature branch, inspect runs for that SHA, fix errors and repeat. A successful
build-only run does not mean tests or real-device checks passed.
