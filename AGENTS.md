# scopebuddy: the Bash framework and per-game configs ScopeBuddy sources at launch

The launcher `/usr/bin/scopebuddy` sources one entry point (`scb.conf`, `noscope.conf`,
`gamemode.conf`) from this checkout in its own shell, under `set -eo pipefail` without `-u`:
there is no build, and an edit is live at the next launch on every host that pulls it.

## Build & run

```bash
tests/run.sh             # every test; no real prefix, no network where `unshare -rn` works
```

## Conventions

- A machine-specific value goes in a gitignored `*.local.env` or `*.local.conf`, never in a
  tracked file; a value a game `.conf` acts on goes in the `.env` pair (`docs/reference.md` §
  Loading order).
- `scripts/**/*.sh`, `games/**/*.{env,conf}` and the entry points are sourced into the
  launcher's shell: they set no shell option, and a public helper returns non-zero only where
  the launch must stop, since at a config's top level that status aborts it (a `__` predicate
  read in a condition may return 1).
- Control flow is `if … then … fi`, one action per line, blank lines between steps, 100
  columns. Output is captured before `grep -q`, an assigned pipeline carries `|| true` or opens
  an `if !`, a fallback is `${var:-…}`, and command output enters `$(( ))` through a variable:
  under `pipefail` and `set -e` the other forms fail, print twice or escape errexit.
- `scripts/` follows the launcher's sections: fixed values in `constants.sh`, values from the
  launch environment and the launch state in `globals.sh`, helpers by topic in `helpers/`, the
  launch phases in `main.sh`.
- Every step of a game config or a `.local` layer opens with a one-line label saying what it
  does for that game, a helper call included; a commented-out code line under its label is a
  switch kept off, not dead code.
- A test covers only behaviour a launch relies on that an edit can break: an abort, a wrong
  registry value, a wrong variable the launcher or Proton reads, a deleted save; a one-line
  setter gets none. Each scenario is a `test_*` function that `run_tests` runs in its own
  `load_framework` sandbox, its fixtures are named functions, and the file ends with
  `run_tests`.
- Every file is in English.

## Docs

- `README.md`: how the launcher loads this checkout, the layout, adding a game config, the
  local overrides and the requirements.
- `docs/reference.md`: read before calling or changing a helper.
