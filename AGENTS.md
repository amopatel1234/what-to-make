# Agent instructions

**Before implementing or reviewing code, read [`docs/project-context.md`](docs/project-context.md).** That file is the canonical source for architecture, testing contracts, and product rules.

## Commits

This repo enforces [Conventional Commits](https://www.conventionalcommits.org/) via `hooks/commit-msg`:

```text
<type>[optional scope][optional !]: <description>
```

Allowed types: `build`, `ci`, `docs`, `fix`, `feat`, `chore`, `style`, `refactor`, `perf`, `test`.

Examples: `fix: prevent duplicate seeded recipes`, `test: cover menu validation`, `feat(images): persist photo filenames`.

Use `!` before `:` for breaking changes. Scope is optional.

## Human setup

See [`README.md`](README.md) for local setup and test commands.

## BMad local artifacts (gitignored)

`_bmad-output/` is **local only** — do not commit it. Cursor search may not index gitignored paths, so BMad workflows must use **explicit full paths** (Read tool or shell), never rely on glob/search alone.

| Artifact | Path |
|----------|------|
| Sprint status | `_bmad-output/implementation-artifacts/sprint-status.yaml` |
| Story files | `_bmad-output/implementation-artifacts/{story-key}.md` |
| Epics / architecture | `_bmad-output/planning-artifacts/` |

If auto-discovery fails, invoke skills with an explicit story id (e.g. `/bmad-create-story 0.1`) or pass the story file path to `/bmad-dev-story`.
