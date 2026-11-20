# Framework

How the checkout is laid out, what the Bash framework in `scripts/` defines, and its constants,
globals and logging helpers.

## How it works

### Layout

```text
scopebuddy/
├── scb.conf / noscope.conf / gamemode.conf   # entry points (one per profile)
├── scripts/        # Bash framework: main, constants, globals, helpers/
├── games/
│   ├── steam/      # per-AppID configs (numeric filename)
│   ├── lutris/     # per-game configs (slug filename)
│   └── rpcs3/      # per-title configs (disc serial filename)
├── mangohud/       # MangoHud config and presets
├── vkbasalt/       # vkBasalt effect presets
├── assets/         # bundled DLLs / installers
├── docs/           # documentation
├── tests/          # launch behaviour tests, run by tests/run.sh
└── tools/          # lint / format / form / doc checks
```

### Scripts

`scripts/` follows the launcher's sections: fixed values in `constants.sh`, values from the
launch environment and the launch state in `globals.sh`, helpers by topic in `helpers/`, the
launch phases in `main.sh` ([loading order](loading-order.md)). The game configs in `games/`
call the helpers, which export the variables the launcher reads (`SCB_*`) and those Proton and
the game process read (`PROTON_*`, `DXVK_*`, `MANGOHUD_*`, …) to control rendering,
compatibility and the overlay.

## Reference

### Constants (`constants.sh`)

| Constant                                                                                                             | Value                                           |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `SCOPEBUDDY_PATH`                                                                                                    | `${SCB_CONFIGDIR}`                              |
| `MANGOHUD_PATH`, `VKBASALT_PATH`, `ASSETS_PATH`, `GAMES_PATH`                                                        | subdirs of `SCOPEBUDDY_PATH`                    |
| `PSPCSDK_EMULATOR_PATH`, `PHYSX_LEGACY_BINARY`                                                                       | bundled assets under `ASSETS_PATH`              |
| `D3D8TO9_VERSION`                                                                                                    | the d3d8to9 release `install_d3d8to9` downloads |
| `SCB_PREFIX_COLOR`, `SCB_SUCCESS_COLOR`, `SCB_WARNING_COLOR`, `SCB_ERROR_COLOR`, `SCB_INFO_COLOR`, `SCB_RESET_COLOR` | ANSI colors of the `[SCB]` log lines            |

### Globals (`globals.sh`)

| Global                                           | Value                                                    |
| ------------------------------------------------ | -------------------------------------------------------- |
| `WINDOWS_USER`                                   | `${WINDOWS_USER:-MatrixDJ96}`                            |
| `USER_DATA_PATH`                                 | `${HOME}/.local/share`                                   |
| `WINDOWS_USER_PATH`                              | `/run/media/${USER}/Windows/Users/${WINDOWS_USER}`       |
| `WINDOWS_ROAMING_PATH`                           | `${WINDOWS_USER_PATH}/AppData/Roaming`                   |
| `COMPAT_TOOL_PATH`                               | first `STEAM_COMPAT_TOOL_PATHS` entry, else `PROTONPATH` |
| `COMPAT_WINE_BINARY`, `COMPAT_WINETRICKS_BINARY` | tools inside `COMPAT_TOOL_PATH`                          |
| `WINEPREFIX`                                     | see below                                                |
| `PREFIX_USER_PATH`                               | `${WINEPREFIX}/drive_c/users/steamuser`                  |
| `PREFIX_ROAMING_PATH`                            | `${PREFIX_USER_PATH}/AppData/Roaming`                    |

`WINEPREFIX` is the `WINEPREFIX` from the launch environment, else
`${STEAM_COMPAT_DATA_PATH}/pfx`, else empty. Built from `STEAM_COMPAT_DATA_PATH` it is not
exported: only the `helpers/wine.sh` helpers pass it to a command.

The Windows-partition paths resolve only when that partition is mounted
([pitfalls](../pitfalls.md#a-save-folder-is-not-linked)).

### Logging and sourcing (`helpers/log.sh`)

| Function                                                                             | Purpose                                                         |
| ------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| `scb_log` / `scb_log_success` / `scb_log_info` / `scb_log_warning` / `scb_log_error` | Print a `[SCB]` line on stdout: plain, green, cyan, yellow, red |
| `source_if_exists`                                                                   | Source `$1` when it is a regular file                           |

`source_if_exists` returns 0 when `$1` is not a regular file; a sourced file that fails, or
ends in a false `cond && action`, aborts the launch.
