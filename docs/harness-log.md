# Harness steering log

When an agent (or human+agent loop) hits the **same** failure twice, encode a lasting guide or computational sensor and add a row here.

| Date | Slip | Encoded as |
|------|------|------------|
| 2026-07-25 | Risk of reintroducing deleted layers / ObservableObject wrappers | `scripts/check-architecture.sh` + PR harness job; [`architecture.md`](architecture.md) |
| 2026-07-25 | Draft PRs skipped all CI sensors | Split workflow: harness job always runs; simulator tests when ready for review |
| 2026-07-25 | Local pushes could skip architecture check | `hooks/pre-push` → `check-architecture.sh`; document `core.hooksPath` |

| 2026-11-07 | Runner defaults and simulator inventory assumed to match the app minimum | Verified `xcode-27` inventory; explicit Xcode selection, locked Fastlane, toolchain/simulator preflight; [`apple-toolchain.md`](apple-toolchain.md) |

| 2026-11-07 | Linux agents could not obtain compiler feedback until a PR was ready | Reusable Apple validation workflow; draft build-for-testing lane; exact-SHA summaries and compiler artifacts |

## How to add an entry

Required follow-up (2026-11-07): remote Apple validation is now an explicit
handoff requirement in `AGENTS.md` and `project-context.md`, with lane selection,
commit matching, failure handling and evidence reporting in `apple-toolchain.md`.
Documenting how to call CI alone was insufficient guidance.

1. Fix the immediate issue.
2. Add or tighten a **guide** (`AGENTS.md` / docs) and/or **sensor** (script, hook, CI).
3. Append a row to the table above in the same PR when practical.
