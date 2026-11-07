# Snapshot baselines — iPhone17-iOS27

Destination: **iPhone 17, iOS 27.0, Xcode 27.0**, matching all Apple CI workflows.
Light appearance, `en_US`, standard Dynamic Type and fixed 402×874 layout remain
unchanged.

New reference PNGs must be recorded and reviewed on this destination. The old
`../iPhone17Pro-iOS26/` images are historical references; do not copy or rename
them into this folder. Ordinary PR tests compare only and fail for missing or
different references.

Run Actions → **Record Snapshot Baselines** on the feature branch, inspect the
four screen PNGs and rerun the PR compare job. The manual workflow injects
`RECORD_SNAPSHOTS=1` and `ALLOW_CI_SNAPSHOT_RECORD=1` into the test plan to reach
the test host, restores the plan and commits only generated PNGs.

Locally, select Xcode 27.0, install the iOS 27.0 runtime and iPhone 17 simulator,
then enable `RECORD_SNAPSHOTS=1` in the scheme's Test environment (shell variables
alone may not reach the test host):

```bash
xcodebuild -workspace whattomake.xcworkspace -scheme whattomake \
  -testPlan UnitTestsPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' test
```

Disable recording and rerun to verify comparison. Never commit recording flags
in the test plan. See [toolchain policy](../../../docs/apple-toolchain.md).
