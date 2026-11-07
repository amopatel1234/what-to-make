# Agent playbook (when things fail)

Short recovery paths. Prefer fixing the harness when the same failure repeats — see [`harness-log.md`](harness-log.md).

## Architecture check failed

```bash
./scripts/check-architecture.sh
```

| Signal | What to do |
|--------|------------|
| `Sources/UseCases` / `Repositories` / `ViewModels` | Delete the folder; put logic in `Helpers/` or a thin coordinator under `Views/` |
| `@Published` / `@StateObject` / `@ObservedObject` | Switch to `@Observable` + `@Bindable` (or view-local `@State`) |

Remediation text from the script is authoritative for the next edit.

## Conventional Commit rejected

Local: `hooks/commit-msg` after `git config core.hooksPath hooks`.  
CI: PR title must match Conventional Commits (Versioning action).

Format: `type: description` — allowed types listed in [`../AGENTS.md`](../AGENTS.md).

## Pre-push blocked by architecture sensor

`hooks/pre-push` runs the same script as CI. Fix the tree, then push again. Do not `--no-verify` unless the human explicitly asks.

## Unit / snapshot tests failed

- Destination must be **iPhone 17**; plan **`UnitTestsPlan`**.
- Snapshots: compare only in the PR workflow; re-record via scheme env `RECORD_SNAPSHOTS=1` on a Mac, or Actions → **Record Snapshot Baselines** — see [`../Tests/__Snapshots__/iPhone17-iOS27/README.md`](../Tests/__Snapshots__/iPhone17-iOS27/README.md).
- On CI failure, download the `apple-validation-<SHA>-<lane>` artifact (`.xcresult` and compiler logs) from the Apple validation job.

## Draft PR: tests did not run

Harness sensors (PR title + architecture check) run on **draft and non-draft** PRs.  
Draft PRs compile app and test targets using `buildForTesting`. Full unit/snapshot tests run when the PR is **ready for review**. Both use the reusable Apple validation workflow; see [`apple-toolchain.md`](apple-toolchain.md).

For behavior, persistence, UI or test changes, dispatch `runUnitTests` on the
current branch even while the PR is a draft. Wait for completion and inspect the
tested SHA, counts and failures before handing off validated work. Do not stop
at a green draft build or report local Xcode unavailability as the end of
verification. See [required validation](apple-toolchain.md#required-validation-before-handoff).

## Wrong workspace / module name

- Open `whattomake.xcworkspace`.
- Tests: `@testable import ForkPlan` (not `whattomake`).
