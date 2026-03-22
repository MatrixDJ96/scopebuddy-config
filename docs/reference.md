# Reference

Helper functions exposed by the bash framework in `scripts/`, which the game
configs in `games/` call.

See [`../README.md`](../README.md) for the overall layout and for how to add a
game config.

Contents: Loading order · Constants (`constants.sh`) · Functions · Proton
variant support.

## Loading order

Each entry point the launcher sources (README § How it works) runs the same
three steps:

1. `source scripts/main.sh` loads `constants.sh`, `globals.sh` and `helpers/`
   and defines the launch phases.
2. `apply_profile_defaults "<profile>"`, then `resolve_game_executable`
   (`GAME_*` from the launch command), then `<profile>.local.conf` if it
   exists.
3. `load_game_configs` resolves the game from `SCB_APPID` and sources the
   game values (`games/<provider>/<id>.env`, then its `.local.env`) and the game
   actions (`games/<provider>/<id>.conf`, then its `.local.conf`). Every profile
   and game file is optional.

Effective override order, last wins:
`<profile>.conf → <profile>.local.conf → game.env → game.local.env → game.conf → game.local.conf`.

## Constants (`constants.sh`)

| Constant                                                                                                             | Value                                           |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `SCOPEBUDDY_PATH`                                                                                                    | `${SCB_CONFIGDIR}`                              |
| `GAMES_PATH`                                                                                                         | subdirs of `SCOPEBUDDY_PATH`                    |
| `SCB_PREFIX_COLOR`, `SCB_SUCCESS_COLOR`, `SCB_WARNING_COLOR`, `SCB_ERROR_COLOR`, `SCB_INFO_COLOR`, `SCB_RESET_COLOR` | ANSI colors of the `[SCB]` log lines            |

## Functions

### `helpers/log.sh`: logging and sourcing

| Function                                                                             | Purpose                                               | Notes                                                                                               |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `scb_log` / `scb_log_success` / `scb_log_info` / `scb_log_warning` / `scb_log_error` | Print a `[SCB]` line: plain, green, cyan, yellow, red | stdout                                                                                              |
| `source_if_exists`                                                                   | Source `$1` when it is a regular file                 | 0 when it is not; a sourced file that fails, or ends in a false `cond && action`, aborts the launch |

### `helpers/launcher.sh`: launcher `SCB_AUTO_*` variables

| Function                 | Exports                                                       |
| ------------------------ | ------------------------------------------------------------- |
| `set_auto_refresh`       | `SCB_AUTO_REFRESH=$1` (`0` or `1`; empty without an argument) |
| `unset_auto_refresh`     | unset `SCB_AUTO_REFRESH`                                      |
| `set_auto_frame_limit`   | `SCB_AUTO_FRAME_LIMIT=$1` (as above)                          |
| `unset_auto_frame_limit` | unset `SCB_AUTO_FRAME_LIMIT`                                  |

The launcher picks the display backend for every `SCB_AUTO_*` feature: KDE, then
GNOME, then wlroots when `jq` and `wlr-randr` are installed. On wlroots without
a gamescope `-O` output it exits with status 1, which aborts the launch, and the
profile defaults turn `SCB_AUTO_RES` and `SCB_AUTO_VRR` on. With no backend, an
`SCB_AUTO_*` a config sets does nothing; one set in the launch options makes the
launcher exit 1 with an error dialog.

| Function                               | Exports                                                                                                                                                                           |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `enable_auto_res` / `disable_auto_res` | `SCB_AUTO_RES` 1 / 0                                                                                                                                                              |
| `enable_auto_vrr` / `disable_auto_vrr` | `SCB_AUTO_VRR` 1 / 0                                                                                                                                                              |
| `enable_auto_hdr` / `disable_auto_hdr` | `SCB_AUTO_HDR` 1 / 0 (launcher: `--hdr-enabled` on the gamescope path when a KDE or GNOME display is in HDR, the Wayland and HDR exports on the no-gamescope path)                |

### `helpers/game.sh`: game executable

| Function                  | Purpose                                                                                                                                                                                                                                       |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resolve_game_executable` | Parse `${command}` for the first absolute `/…/*.exe` path (any case); set `GAME_FILENAME`, `GAME_DIRECTORY`, `GAME_EXECUTABLE`                                                                                                                |
| `replace_game_executable` | Swap `GAME_EXECUTABLE` for a new path inside `${command}`; without an argument it leaves an empty `""` word in `${command}` where the executable was, and `restore_game_executable` then returns 0 but leaves that word, so pass the new path |
| `restore_game_executable` | Revert to the executable captured on the first swap; status 1, silent, when no swap came first                                                                                                                                                |

### `main.sh`: launch phases

| Function                 | Purpose                                                                                                                                                                                                                                            |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `apply_profile_defaults` | Accept `scb`, `noscope` or `gamemode`: the `SCB_AUTO_*` toggles; log and return 1 on any other name                                                                                                                                                |
| `load_game_configs`      | Source the game `.env` and `.local.env`, then the game config and its `.local.conf`; then unset `SCB_APPID`                                                                                                                                        |

## Proton variant support

Tested with the versions below. Update this section when ScopeBuddy or Proton
is upgraded.

| Component           | Version                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------ |
| ScopeBuddy launcher | `ScopeBuddy-1.5.0-3.fc45.noarch`                                                           |
| Proton-CachyOS      | `cachyos-11.0-20261015-slr` (vkd3d-proton 3.1.0, DXVK `v3.1.1-97-ga78a467cadb22be-pcos`)   |
| Proton-GE           | `GE-Proton11-12` (vkd3d-proton 3.1.0, DXVK `v3.1.1-174-gf86377680682448-GE-Proton(dirty)`) |

Read the installed build id from `version` in each compatibility-tool directory,
and the component versions from the `vkd3d-proton` and `dxvk` DLLs those
directories ship.
