# Harness steering log

When an agent (or human+agent loop) hits the **same** failure twice, encode a lasting guide or computational sensor and add a row here.

| Date | Slip | Encoded as |
|------|------|------------|
| 2026-07-25 | Risk of reintroducing deleted layers / ObservableObject wrappers | `scripts/check-architecture.sh` + PR harness job; [`architecture.md`](architecture.md) |
| 2026-07-25 | Draft PRs skipped all CI sensors | Split workflow: harness job always runs; simulator tests when ready for review |
| 2026-07-25 | Local pushes could skip architecture check | `hooks/pre-push` → `check-architecture.sh`; document `core.hooksPath` |

## How to add an entry

1. Fix the immediate issue.
2. Add or tighten a **guide** (`AGENTS.md` / docs) and/or **sensor** (script, hook, CI).
3. Append a row to the table above in the same PR when practical.
