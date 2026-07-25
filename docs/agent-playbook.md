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

- Destination must be **iPhone 17 Pro**; plan **`UnitTestsPlan`**.
- Snapshots: compare only in the PR workflow; re-record via scheme env `RECORD_SNAPSHOTS=1` on a Mac, or Actions → **Record Snapshot Baselines** — see [`../Tests/__Snapshots__/iPhone17Pro-iOS26/README.md`](../Tests/__Snapshots__/iPhone17Pro-iOS26/README.md).
- On CI failure, download the `test-results` artifact (`.xcresult`) from the PR workflow.

## Draft PR: tests did not run

Harness sensors (PR title + architecture check) run on **draft and non-draft** PRs.  
Full Fastlane unit/snapshot job runs only when the PR is **ready for review** (`draft == false`). Mark the PR ready to get simulator CI.

## Wrong workspace / module name

- Open `whattomake.xcworkspace`.
- Tests: `@testable import ForkPlan` (not `whattomake`).
