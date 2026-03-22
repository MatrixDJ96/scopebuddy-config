# ScopeBuddy configuration

Personal configuration for the
[ScopeBuddy](https://github.com/OpenGamingCollective/ScopeBuddy) launcher, a
Steam / Lutris / Heroic launch wrapper that runs the game's command, inside
gamescope or without it. This repo holds the bash framework and the per-game
configs that ScopeBuddy sources at launch.

Contents: How it works · Layout · Add a game config · Local overrides ·
Requirements.

## How it works

ScopeBuddy is installed at `/usr/bin/scopebuddy` and reads this checkout from
`$SCB_CONFIGDIR`, which it sets to `$XDG_CONFIG_HOME/scopebuddy`
(`~/.config/scopebuddy` when `XDG_CONFIG_HOME` is unset): clone this repository
there. At launch the launcher selects one entry point based on the
environment: `gamemode.conf` when Steam runs in Game Mode, else the file
`SCB_CONF` names (default `scb.conf`), and `noscope.conf` instead of the default
when gamescope is unavailable or `SCB_NOSCOPE=1`. Each entry point loads the
framework, the profile defaults and the game's config files in the order
[`docs/reference.md`](docs/reference.md) § Loading order gives.

## Layout

```text
scopebuddy/
├── scb.conf / noscope.conf / gamemode.conf   # entry points (one per profile)
├── scripts/        # bash framework: main, constants, globals, helpers/
├── games/
│   ├── steam/      # per-AppID configs (numeric filename)
│   └── lutris/     # per-game configs (slug filename)
├── docs/           # reference documentation
└── tests/          # launch behaviour tests, run by tests/run.sh
```

## Add a game config

1. Route the game through ScopeBuddy: Steam launch options `scb -- %command%`;
   Lutris, the game's command prefix `scb --`. Without it no `[SCB]` line
   appears and no config is read.
2. Find the ID. Steam: the number in the store URL or on steamdb.info, saved
   as `games/steam/<appid>.conf`. Heroic and Ubisoft are auto-detected from
   their URI schemes; save under `games/heroic/<id>.conf` or
   `games/ubisoft/<id>.conf`. Any other launcher (Lutris, RPCS3) is not
   detected: set `SCB_APPID=<provider>/<id>` in the game's environment (Lutris:
   the game's environment variables) and save as `games/<provider>/<id>.conf`.
3. Add helper calls. The existing files in `games/` are the working examples:
   copy the closest one and adjust.
4. Launch the game once and read the `[SCB]` lines the framework prints on the
   launcher's stdout (Steam started from a terminal shows them):
   `__game_config` names the file that was resolved. Check it is the file you
   just wrote: a wrong provider or id resolves to a path that does not exist,
   and the launch continues silently with the profile defaults alone. A launch
   the launcher does not detect (Lutris without `SCB_APPID`) arrives as `null`
   and resolves to `games/steam/null.conf`.

## Local overrides

Any `*.local.conf` or `*.local.env` is gitignored; the ones below are layered on
their tracked file (the shell layers sourced). Use them for machine-specific or
experimental settings:

- `scb.local.conf`, `noscope.local.conf`, `gamemode.local.conf`: overrides for
  each profile
- `games/<provider>/<id>.local.env`: per-game local values
  (resolution, refresh rate)
- `games/<provider>/<id>.local.conf`: per-game local tweak

Which layer a value belongs in: [`docs/reference.md`](docs/reference.md)
§ Loading order.

## Requirements

- ScopeBuddy launcher, tested with 1.5.0; Proton-CachyOS or Proton-GE. The
  tested builds are in [`docs/reference.md`](docs/reference.md) § Proton variant
  support.
