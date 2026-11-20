# Loading order

Which files a launch sources, in which order, and which layer a value belongs in.

## How it works

### Entry points

ScopeBuddy is installed at `/usr/bin/scopebuddy` and reads this checkout from `$SCB_CONFIGDIR`,
which it sets to `$XDG_CONFIG_HOME/scopebuddy` (`~/.config/scopebuddy` when `XDG_CONFIG_HOME`
is unset). At launch the launcher selects one entry point based on the environment:
`gamemode.conf` when Steam runs in Game Mode, else the file `SCB_CONF` names (default
`scb.conf`), and `noscope.conf` instead of the default when gamescope is unavailable or
`SCB_NOSCOPE=1`. Each entry point is a profile: `scb`, `noscope` or `gamemode`.

### Three steps

Each entry point runs the same three steps:

1. `source scripts/main.sh` loads `constants.sh`, `globals.sh` and `helpers/` and defines the
   launch phases.
2. `apply_profile_defaults "<profile>"`, then `resolve_game_executable` (`GAME_*` from the
   launch command), then `<profile>.local.conf` if it exists.
3. `load_game_configs` resolves the game from `SCB_APPID` and sources the game values
   (`games/<provider>/<id>.env`, then its `.local.env`) and the game actions
   (`games/<provider>/<id>.conf`, then its `.local.conf`). Every profile and game file is
   optional.

### Launch kind

`resolve_game_executable` sets `SCB_GAME_NATIVE` once: 0 for a Windows launch (an absolute
`.exe` in `${command}` and a `WINEPREFIX`), 1 otherwise (a Linux build, an RPCS3 title). The
helpers do not check `GAME_*` or `WINEPREFIX`: a config for a Windows-only game assumes a
Windows launch, and a file serving both kinds branches on `SCB_GAME_NATIVE`
(`games/steam/427520.conf`).

### Override order

Effective override order, last wins:

```text
<profile>.conf → <profile>.local.conf → game.env → game.local.env → game.conf → game.local.conf
```

The `.env` pair sets the values a game config reads (`games/lutris/warcraft-iii.env` is the
example), so every value is in place before the `.conf` writes it into the prefix or a
gamescope flag.

### Local layers

Any `*.local.conf` or `*.local.env` is gitignored; the ones below are layered on their tracked
file (the shell layers sourced, the MangoHud ones appended), and a vkBasalt preset has no
`.local` layer. They hold machine-specific or experimental settings:

- `scb.local.conf`, `noscope.local.conf`, `gamemode.local.conf`: overrides for each profile
- `mangohud/MangoHud.local.conf`, `mangohud/presets.local.conf`: machine-specific overlay and
  presets
- `games/<provider>/<id>.local.env`: per-game local values (resolution, refresh rate)
- `games/<provider>/<id>.local.conf`: per-game local tweak

### Profile defaults

On the desktop the `scb` and `noscope` profiles start in standalone-MangoHud mode and a game
config opts into gamescope with `enable_gamescope`. The defaults overwrite the same variables
set in the launch options: set those in a `.local.conf` instead.

### Game Mode

- In Game Mode the launcher forces `SCB_NOSCOPE=1` before the configs and `MANGOHUD=0` after
  them, but branches on `SCB_NOSCOPE` only after the configs ran, so a config that set it to 0
  would start a nested gamescope, which fails.
- Without the gamescope binary (`GAMESCOPE_BIN`, default `gamescope`) the launcher also forces
  `SCB_NOSCOPE=1`.
- Anywhere else, with the gamescope binary installed, a config calling `enable_gamescope` wins
  over an `SCB_NOSCOPE=1` set at launch: the launcher sourced `noscope.conf` and runs
  gamescope.

## Reference

### Launch phases (`main.sh`)

| Function                 | Purpose                                                              |
| ------------------------ | -------------------------------------------------------------------- |
| `apply_profile_defaults` | Apply a profile's defaults; log and return 1 on an unknown profile   |
| `load_game_configs`      | Source the game's files, then drop Steam's pad variables when needed |

`apply_profile_defaults` accepts `scb`, `noscope` or `gamemode`. It sets the `SCB_AUTO_*`
toggles, WOW64, NTSYNC, Proton's Wayland driver, Steam Input off (X11 sessions included), and
the MangoHud files, then calls `disable_gamescope` (`scb`, `noscope`) or `enable_gamescope`
(`gamemode`).

`load_game_configs` sources the game `.env` and `.local.env`, then the game config and its
`.local.conf`. Then, with `PROTON_NO_STEAMINPUT` non-zero, it unsets
`SDL_GAMECONTROLLER_ALLOW_STEAM_VIRTUAL_GAMEPAD`, `SDL_GAMECONTROLLER_IGNORE_DEVICES` and
`SteamVirtualGamepadInfo`: both builds unset them on their Wayland path; on X11, by default,
Steam's ignore list keeps hiding the physical pad.
