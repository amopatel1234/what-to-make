# what-to-make (ForkPlan)

An iOS app for saving recipes and generating a randomized weekly menu. Built with SwiftUI, SwiftData, and Swift Concurrency.

## Requirements

- macOS with **Xcode 26+**
- **iOS 26+** simulator/runtime
- Ruby/Bundler (for Fastlane CI automation)

## Quick start

```bash
open whattomake.xcworkspace
```

Run the app from Xcode using the `whattomake` scheme. The built product is `ForkPlan.app`.

Optional setup for Fastlane:

```bash
bundle install
```

## Tests

```bash
# Unit tests
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test

# UI tests
xcodebuild \
  -workspace whattomake.xcworkspace \
  -scheme whattomake \
  -testPlan UITestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test

# Same as CI
WORKSPACE="$PWD" WORKSPACE_FILENAME="whattomake.xcworkspace" \
SCHEME="whattomake" TEST_PLAN="UnitTestsPlan" \
bundle exec fastlane runUnitTests
```

## Documentation

| Doc | Audience | Purpose |
|-----|----------|---------|
| [`AGENTS.md`](AGENTS.md) | AI agents (auto-discovered) | Entry point — points to project-context + commit rules |
| [`docs/project-context.md`](docs/project-context.md) | AI agents & developers | Implementation rules, architecture, testing contracts |
| [`docs/index.md`](docs/index.md) | App users | Privacy policy (GitHub Pages) |
| [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | PR reviewers | Code review priorities |

## License

MIT. See [LICENSE](LICENSE).
