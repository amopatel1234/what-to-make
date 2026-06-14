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
