# scopebuddy: the Bash framework and per-game configs ScopeBuddy sources at launch

The launcher `/usr/bin/scopebuddy` sources one entry point (`scb.conf`, `noscope.conf`,
`gamemode.conf`) from this checkout in its own shell, under `set -eo pipefail` without `-u`:
there is no build, and an edit is live at the next launch on every host that pulls it.

## Build & run

```bash
tools/lint.sh            # shellcheck over the shell sources, the *.local.* layers excluded
tools/format.sh --check  # shfmt diff; bare, it rewrites the files in place
tools/check-form.sh      # line width and the banned shell shapes
tools/check-docs.sh      # docs/helpers/ and docs/architecture/ tables vs scripts/, both ways
tests/run.sh             # every test; no real prefix, no network where `unshare -rn` works
```

The gates need `shellcheck`, `shfmt`, `python3`, `jq` and `/usr/bin/curl`; without `jq` the
Warcraft III check in `tests/main.sh` and the HDR check in `tests/helpers/gamescope.sh` fail.

All five run before every commit; after editing `tools/check-form.sh`, `tools/check-docs.sh` or
`tests/run.sh`, its `--self-test` runs too.

## Conventions

- A public function or exported variable name (`PROTON_*`, `DXVK_*`, `SCB_*`, `MANGOHUD_*`) is
  read by a game config, the launcher, Proton or a Vulkan layer (MangoHud): add a helper, never
  rename one.
- A machine-specific value goes in a gitignored `*.local.env` or `*.local.conf`, never in a
  tracked file; a value a game `.conf` acts on goes in the `.env` pair
  (`docs/architecture/loading-order.md` § Override order).
- `scripts/**/*.sh`, `games/**/*.{env,conf}` and the entry points are sourced into the
  launcher's shell: they set no shell option, and a public helper returns non-zero only where
  the launch must stop, since at a config's top level that status aborts it (a `__` predicate
  read in a condition may return 1).
- `tools/*.sh` and `tests/run.sh` open with `#!/usr/bin/env bash`, `set -euo pipefail` and a
  header (what it does, `Usage:`, output, exit status).
- Control flow is `if … then … fi`, one action per line, blank lines between steps, 100
  columns. Output is captured before `grep -q`, an assigned pipeline carries `|| true` or opens
  an `if !`, a fallback is `${var:-…}`, and command output enters `$(( ))` through a variable:
  under `pipefail` and `set -e` the other forms fail, print twice or escape errexit.
  `tools/check-form.sh` reads the rules its header lists, review reads the rest; a line holding
  a banned shape as data ends in `# form: literal`.
- `scripts/` follows the launcher's sections: `docs/architecture/framework.md` § Scripts.
- A module opens with one sentence saying what it provides; a helper or state variable no game
  config, `.local` layer or entry point is meant to call or touch starts with `__` (`_` is kept
  by three `proton.sh` helpers; do not add more).
- Every step of a game config or a `.local` layer opens with a one-line label saying what it
  does for that game, a helper call included; a commented-out code line under its label is a
  switch kept off, not dead code.
- A test covers only behaviour a launch relies on that an edit can break: an abort, a wrong
  registry value, a wrong variable the launcher or Proton reads, a deleted save; a one-line
  setter gets none. Each scenario is a `test_*` function that `run_tests` runs in its own
  `load_framework` sandbox, its fixtures are named functions, and the file ends with
  `run_tests`.
- A public function gets a row in a function table of `docs/helpers/` or `docs/architecture/`,
  whose first cell names it: `tools/check-docs.sh` reads only the tables of those two folders.
- A guard (`tools/check-form.sh`, `tools/check-docs.sh`, `tests/run.sh`) ships a `--self-test`
  that feeds it known-bad input and requires the failure.
- Every file is in English.

## Gotchas

- A test that reads MangoHud sets `MANGOHUD_PATH` to a fixture: the host's gitignored
  `mangohud/MangoHud.local.conf` would otherwise change the expected value.

## Docs

- `docs/README.md`: read first to find which doc covers a task.
- `docs/helpers/<topic>.md`: read before calling or changing a helper of
  `scripts/helpers/<topic>.sh`; `log.sh` is in `docs/architecture/framework.md`, `main.sh` in
  `docs/architecture/loading-order.md`.
