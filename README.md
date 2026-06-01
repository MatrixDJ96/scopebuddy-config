# ScopeBuddy Configuration

Personal configuration for the [ScopeBuddy](https://github.com/HikariKnight/ScopeBuddy)
launcher — a Steam / Lutris / Heroic compatibility wrapper around gamescope and
Proton. This repo holds the bash framework and the per-game configs that
ScopeBuddy sources at launch.

## How it works

ScopeBuddy is installed at `/usr/bin/scopebuddy` and reads this checkout from
`$SCB_CONFIGDIR`, which it sets to `$XDG_CONFIG_HOME/scopebuddy` — clone this
repository there. At launch the launcher selects one entry point based on the
environment: `gamemode.conf` when Steam runs in Game Mode, `noscope.conf` when
gamescope is unavailable or `SCB_NOSCOPE=1`, and `scb.conf` otherwise. Each
entry point:

1. sources `scripts/bootstrap.sh`, which loads the framework modules;
2. applies the profile defaults and the optional `<profile>.local.conf`;
3. resolves the game executable, then sources the matching
   `games/<provider>/<id>.conf` and its `.local.conf`.

The three profiles share one set of defaults, so what separates them is which
`<profile>.local.conf` gets sourced. Those defaults leave gamescope off and
MangoHud standalone; a game config opts into gamescope by calling
`enable_gamescope`.

The framework exports environment variables (`PROTON_*`, `DXVK_*`, `SCB_*`,
`MANGOHUD_*`, …) into the game process to control rendering, compatibility and
the overlay. See [`docs/reference.md`](docs/reference.md) for every helper and
the Proton variant support section.

## Layout

```text
scopebuddy/
├── scb.conf / noscope.conf / gamemode.conf   # entry points (one per profile)
├── scripts/        # bash framework, sourced via bootstrap.sh
├── games/
│   ├── steam/      # per-AppID configs (numeric filename)
│   └── lutris/     # per-game configs (slug filename)
├── mangohud/       # MangoHud config and presets
├── assets/         # bundled DLLs / installers (Git LFS)
├── docs/           # reference documentation
└── tools/          # lint / format / doc checks
```

## Add a game config

1. Find the ID — Steam: the number in the store URL or on steamdb.info; Lutris:
   the game slug. Save as `games/steam/<appid>.conf` or
   `games/lutris/<slug>.conf`. Heroic and Ubisoft are auto-detected from their
   URI schemes; save under `games/heroic/<id>.conf` or `games/ubisoft/<id>.conf`.
2. Add helper calls. The existing files in `games/` are the working examples —
   copy the closest one and adjust.

```bash
# <Game Title>

enable_dlss_override
set_framerate_limit 120
```

3. Launch the game once and read the `[SCB]` lines the framework prints — Steam
   surfaces them in the launch output, and `SCB_GAME_CONFIG` names the file that
   was resolved. Check it is the file you just wrote: a wrong provider or id
   resolves to a path that does not exist, and the launch continues silently
   with the profile defaults alone.

See [`docs/reference.md`](docs/reference.md) for the full helper list, and
`scripts/profiles.sh` for the toggles every profile applies by default.

## Local overrides

Any `*.local.conf` is gitignored and sourced *after* the tracked file, so it
wins on conflict. Use it for machine-specific or experimental settings:

- `scb.local.conf` — overrides for the desktop profile
- `mangohud/MangoHud.local.conf` — machine-specific overlay
- `games/<provider>/<id>.local.conf` — per-game local tweak

## Tooling

All three exit 0 on success; run them before committing:

- `tools/lint.sh` — shellcheck every shell source: `scripts/`, `games/`,
  `tools/` and the root profile configs. Read-only
- `tools/format.sh [--check]` — shfmt over the same set; bare it rewrites the
  files in place, `--check` reports diffs without writing
- `tools/check-docs.sh` — verify the helper tables in `docs/reference.md` match
  the functions defined in `scripts/`. Read-only

## Requirements

- ScopeBuddy launcher ≥ 1.4.0.
- Proton-CachyOS or Proton-GE (see the tested builds in the reference).
- Git LFS for `assets/`.
- *Optional:* a dual-boot Windows partition mounted at
  `/run/media/$USER/Windows` for configs that symlink save data; those configs
  no-op when it is absent.
