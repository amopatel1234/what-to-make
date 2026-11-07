fastlane documentation
----

# Installation

Install full Xcode 27.0 with the iOS 27.0 SDK and iPhone 17 simulator, then select it:

```sh
export DEVELOPER_DIR=/Applications/Xcode_27.app/Contents/Developer
bundle install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios runUnitTests

```sh
[bundle exec] fastlane ios runUnitTests
```

Run unit and snapshot tests (UnitTestsPlan) on pinned iPhone 17 / iOS 27.0 simulator.
Requires `WORKSPACE_FILENAME`, `SCHEME` and `TEST_PLAN`. Fastlane validates the
selected toolchain and exact simulator before running tests. See
[toolchain policy](../docs/apple-toolchain.md).

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy to App Store Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
