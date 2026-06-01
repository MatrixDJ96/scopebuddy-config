# Agent and Contributor Guide

Conventions for anyone — humans or AI agents (Claude, Gemini, Codex, …) — making
changes in this repository. Read this before implementing or committing.

## Architecture

ScopeBuddy sources one entry point (`scb.conf`, `noscope.conf`, `gamemode.conf`),
which loads `scripts/bootstrap.sh`, then the framework modules in dependency
order, applies the profile defaults, and finally sources the matching game
config. The three profiles share one default set; the entry point decides which
`<profile>.local.conf` is sourced.
See [`docs/reference.md`](docs/reference.md) for the module and helper list, the
loading order and the effective override chain.

## Stable contract — do not break

- **Public function names** are an API: the per-game configs under `games/` call
  them. Never rename a public helper; add a new one if you need different
  behaviour.
- **Exported variable names** (`PROTON_*`, `DXVK_*`, `SCB_*`, `MANGOHUD_*`, …)
  are read by the launcher and by Proton. Never rename them.
- Edits to `scripts/` may refactor internals, but must keep these names and the
  observable effects intact.

## Shell style

- Bash, formatted with shfmt and linted with shellcheck (see `tools/`).
- Comments: one short header per module and one synthetic line per function. A
  second line earns its place when it carries something the call site cannot
  show — a destructive effect, a mandatory ordering, a companion variable the
  caller must set. Inside a block of toggles, a short label per group keeps the
  defaults scannable.
- Document the present state only. No change-log narration in comments or docs
  ("now uses…", "previously…", "refactored to…", "instead of…"). Describe what
  the code does today, or delete the comment.
- English, for every file in the repo.
- Private helpers are prefixed with `_`. A double underscore marks what stays
  internal to the framework — both functions and state — and never appears in a
  game config.

## Documentation

- Keep it minimal: `README.md` plus `docs/reference.md` (table-driven). The
  configs under `games/` and the defaults in `scripts/profiles.sh` are the worked
  examples — there is no separate cookbook document and no per-game
  compatibility-matrix document.
- `docs/reference.md` cites files and functions by name, never by line number.
- Every public function must appear in a reference helper table, and every
  function named in a table must exist. `tools/check-docs.sh` enforces both.

## Before every commit

Run all three and keep them green:

```bash
tools/lint.sh
tools/format.sh --check
tools/check-docs.sh
```

## Commit style

- Short, descriptive, imperative English subjects.
- Split a body of work into commits by theme — e.g. repository setup, framework
  implementation, tooling, settings, game configs, documentation — rather than
  one large mixed commit.
- Keep the subjects of a related series roughly the same length for a tidy log.
- No AI attribution trailer (`Co-Authored-By`, `Generated-By`, …) unless the
  author explicitly asks for it on a specific commit.

## Local overrides

Never commit machine-specific values into the tracked configs: they belong in a
`*.local.conf`, which [`README.md`](README.md) describes in full.
