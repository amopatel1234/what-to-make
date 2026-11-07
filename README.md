# what-to-make (ForkPlan)

An iOS app for saving recipes and generating a randomized weekly menu. Built with SwiftUI, SwiftData, and Swift Concurrency.

## Requirements

- macOS with **Xcode 27**
- **Swift 6.0** with strict concurrency enabled
- **iOS 27.0** simulator/runtime
- Ruby/Bundler (for Fastlane CI automation)

ForkPlan follows the latest major iOS release; this update requires iOS 27.0.
Users remaining on iOS 26 cannot install it. CI uses the verified `xcode-27`
runner, explicitly selected Xcode 27.0 and locked Fastlane dependencies.
See [toolchain policy and upgrade validation](docs/apple-toolchain.md).

## Quick start

```bash
open whattomake.xcworkspace
```

Run the app from Xcode using the `whattomake` scheme. The built product is `ForkPlan.app`.

Optional setup for Fastlane and local agent harness hooks (commit-msg + pre-push architecture check):

```bash
export DEVELOPER_DIR=/Applications/Xcode_27.app/Contents/Developer
bundle install
git config core.hooksPath hooks
./scripts/check-architecture.sh
```

## Tests

Unit and snapshot tests run on the pinned **iPhone 17 / iOS 27.0** simulator. See [`Tests/__Snapshots__/iPhone17-iOS27/README.md`](Tests/__Snapshots__/iPhone17-iOS27/README.md) for re-recording baselines (scheme env vars) and CI compare mode.

```bash
# Unit and snapshot tests (pinned simulator)
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  test

# Same as CI
WORKSPACE_FILENAME="whattomake.xcworkspace" \
SCHEME="whattomake" TEST_PLAN="UnitTestsPlan" \
bundle exec fastlane runUnitTests
```

## Documentation

| Doc | Audience | Purpose |
|-----|----------|---------|
| [`AGENTS.md`](AGENTS.md) | AI agents (auto-discovered) | Map / TOC into deeper docs + harness commands |
| [`docs/project-context.md`](docs/project-context.md) | AI agents & developers | Implementation rules, testing contracts, product rules |
| [`docs/ux-design.md`](docs/ux-design.md) | AI agents & developers | Screens, interaction flows, visual tokens, UX principles |
| [`docs/architecture.md`](docs/architecture.md) | AI agents & developers | Folder boundaries and forbidden state wrappers |
| [`docs/agent-playbook.md`](docs/agent-playbook.md) | AI agents | Recovery paths when checks/CI fail |
| [`docs/harness-log.md`](docs/harness-log.md) | AI agents & developers | Steering log — encode repeated slips into guides/sensors |
| [`docs/index.md`](docs/index.md) | App users | Privacy policy (GitHub Pages) |
| [`fastlane/testing_notes.txt`](fastlane/testing_notes.txt) | Testers / App Store Connect | What to Test notes for the next TestFlight upload |

Update `fastlane/testing_notes.txt` with a short sentence before opening a PR that will eventually ship; Fastlane `deploy` reads it when uploading to App Store Connect.

## License

MIT. See [LICENSE](LICENSE).
