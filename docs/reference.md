# Reference

Helper functions exposed by the bash framework in `scripts/`, which the game
configs in `games/` call.

See [`../README.md`](../README.md) for the overall layout and for how to add a
game config.

Contents: Loading order · Constants (`constants.sh`) · Globals (`globals.sh`) ·
Functions · Proton variant support · Caveats · Variables without a helper.

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

The `.env` pair sets the values a game config reads
(`games/lutris/warcraft-iii.env` is the example), so every value is in place
before the `.conf` writes it into the prefix or a gamescope flag.

## Constants (`constants.sh`)

| Constant                                                                                                             | Value                                           |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `SCOPEBUDDY_PATH`                                                                                                    | `${SCB_CONFIGDIR}`                              |
| `MANGOHUD_PATH`, `ASSETS_PATH`, `GAMES_PATH`                                                                         | subdirs of `SCOPEBUDDY_PATH`                    |
| `PSPCSDK_EMULATOR_PATH`, `PHYSX_LEGACY_BINARY`                                                                       | bundled assets under `ASSETS_PATH`              |
| `D3D8TO9_VERSION`                                                                                                    | the d3d8to9 release `install_d3d8to9` downloads |
| `SCB_PREFIX_COLOR`, `SCB_SUCCESS_COLOR`, `SCB_WARNING_COLOR`, `SCB_ERROR_COLOR`, `SCB_INFO_COLOR`, `SCB_RESET_COLOR` | ANSI colors of the `[SCB]` log lines            |

## Globals (`globals.sh`)

| Global                                           | Value                                                                                                                                                                                                       |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `WINDOWS_USER`                                   | `${WINDOWS_USER:-MatrixDJ96}`                                                                                                                                                                               |
| `USER_DATA_PATH`                                 | `${HOME}/.local/share`                                                                                                                                                                                      |
| `WINDOWS_USER_PATH`                              | `/run/media/${USER}/Windows/Users/${WINDOWS_USER}`                                                                                                                                                          |
| `WINDOWS_ROAMING_PATH`                           | `${WINDOWS_USER_PATH}/AppData/Roaming`                                                                                                                                                                      |
| `COMPAT_TOOL_PATH`                               | first `STEAM_COMPAT_TOOL_PATHS` entry, else `PROTONPATH`                                                                                                                                                    |
| `COMPAT_WINE_BINARY`, `COMPAT_WINETRICKS_BINARY` | tools inside `COMPAT_TOOL_PATH`                                                                                                                                                                             |
| `WINEPREFIX`                                     | `WINEPREFIX` from the launch environment, else `${STEAM_COMPAT_DATA_PATH}/pfx` (not exported when built from `STEAM_COMPAT_DATA_PATH`: only the `helpers/wine.sh` helpers pass it to a command), else empty |
| `PREFIX_USER_PATH`                               | `${WINEPREFIX}/drive_c/users/steamuser`                                                                                                                                                                     |
| `PREFIX_ROAMING_PATH`                            | `${PREFIX_USER_PATH}/AppData/Roaming`                                                                                                                                                                       |

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

Both variables are booleans the launcher reads. On `1` the launcher detects the
display and injects gamescope `-r <detected refresh>` or `--framerate-limit
<detected refresh>`; it tests each value with `-eq 1`, so any other value leaves
the feature off; an empty, unset or non-integer value also makes it print a `[:
…: integer expected` line (bash 5.3; translated under a non-English locale).
Both act on gamescope's arguments, so on the gamescope path alone, and
`SCB_AUTO_REFRESH=1` replaces the `-r` that `set_framerate_limit` set, as
`SCB_AUTO_RES=1` (a profile default) replaces any `-W` / `-H` a config adds. Use
`set_framerate_limit` to cap fps at a chosen number.

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
| `enable_auto_hdr` / `disable_auto_hdr` | `SCB_AUTO_HDR` 1 / 0 (launcher: `--hdr-enabled` on the gamescope path when a KDE or GNOME display is in HDR, the Wayland and HDR exports on the no-gamescope path; see HDR below) |

### `helpers/gamescope.sh`: gamescope flags, framerate and MangoHud

| Function                | Purpose                                                                                                                                                                                                                                                                                                                                                                                  |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `add_gamescope_flag`    | Append flags to `SCB_GAMESCOPE_ARGS`, skipping duplicates; a flag and its value go in one argument (`"-w 1920"`)                                                                                                                                                                                                                                                                         |
| `remove_gamescope_flag` | Remove the given flags from `SCB_GAMESCOPE_ARGS`, each matched whole (`"-w 1920"`, not `-w`)                                                                                                                                                                                                                                                                                             |
| `enable_gamescope`      | Gamescope mode: `MANGOHUD=0`, `SCB_NOSCOPE=0`, `PROTON_ENABLE_WAYLAND=0` when it was on (remembered for `disable_gamescope`), add `--mangoapp -f`, and `--hdr-enabled` when `kscreen-doctor` reports the primary output in HDR (needs `jq`; without it the flag is never added); in Game Mode or without the gamescope binary, a warning and `disable_gamescope` instead (see `main.sh`) |
| `disable_gamescope`     | Standalone MangoHud: `MANGOHUD=1`, `SCB_NOSCOPE=1`, `PROTON_ENABLE_WAYLAND=1` again when gamescope turned it off and no `disable_proton_wayland` ran since; in Game Mode, where the game runs in Steam's gamescope, `PROTON_ENABLE_WAYLAND=0` when it was on, as `enable_gamescope` does; remove `--mangoapp -f --hdr-enabled`                                                           |
| `set_framerate_limit`   | Cap fps (60 without an argument); routes to gamescope `-r` or `PROTON_FRAME_RATE` per mode                                                                                                                                                                                                                                                                                               |

`set_framerate_limit` reads `SCB_NOSCOPE` to choose the path, so it is safe to
call before `enable_gamescope` / `disable_gamescope`: the limit is re-applied on
every mode change, and each change first unsets `PROTON_FRAME_RATE` and strips
any gamescope `-r`, so only a limit set through `set_framerate_limit` survives
it. Without gamescope, Proton turns `PROTON_FRAME_RATE` into DXVK's
`dxgi.maxFrameRate` and `d3d9.maxFrameRate`, so the cap reaches the D3D9–D3D12
games DXVK and vkd3d-proton render (D3D8 too, under `enable_proton_dxvk_d3d8` or
through `install_d3d8to9`), not OpenGL, native Vulkan or wined3d ones, and a set
`DXVK_FRAME_RATE` or `VKD3D_FRAME_RATE` wins over it. The launcher uses
`SCB_GAMESCOPE_ARGS` only when the launch options pass no gamescope arguments
before `--` (unless `SCB_APPENDMODE=1`); otherwise every flag these helpers set
is dropped. Every flag helper above rebuilds `SCB_GAMESCOPE_ARGS` from its own
list: a value from the launch environment is gone once the profile defaults run,
and one a config assigns directly lasts only until the next helper call, so a
flag goes through `add_gamescope_flag`.

| Function              | Exports                                          |
| --------------------- | ------------------------------------------------ |
| `set_mangohud_config` | `MANGOHUD_CONFIGFILE` and `MANGOHUD_PRESETSFILE` |

Each file is the base, or the base with its `.local` layer merged; the base,
with an error, when the merge fails.

### `helpers/proton.sh`: Proton, DXVK, vkd3d and GPU variables

| Function                                                           | Exports                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Variant          |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `enable_proton_wow64` / `disable_proton_wow64`                     | `PROTON_USE_WOW64` 1 / 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | both             |
| `enable_proton_ntsync` / `disable_proton_ntsync`                   | `PROTON_NO_FSYNC` 1 / 0; NTSYNC itself stays on where the kernel provides `/dev/ntsync` (`PROTON_NO_NTSYNC`, which both builds' `wineserver` reads, turns it off)                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | both             |
| `enable_proton_wayland` / `disable_proton_wayland`                 | `PROTON_ENABLE_WAYLAND` 1 / 0; both builds switch to the Wayland driver only when `WAYLAND_DISPLAY` is set, and both let a `PROTON_USE_WAYLAND` from the launch options win over it; on that driver CachyOS turns Steam Input off (`PROTON_NO_STEAMINPUT` defaults to `1`, so a controller reaches the game without its Steam Input layout; export `PROTON_NO_STEAMINPUT=0` to keep it), while GE keeps it when the game's Steam Input toggle is on; ScopeBuddy's own sample config warns that the Wayland mode "will break the steam overlay" (`/usr/bin/scopebuddy`), and GE ships a `steam-overlay-wayland` layer that CachyOS lacks | both             |
| `enable_proton_vkreflex` / `disable_proton_vkreflex`               | `DXVK_NVAPI_VKREFLEX` 1 / 0; both builds load the Reflex layer only when the `nvidia` kernel module is loaded and NVAPI is not disabled (`PROTON_DISABLE_NVAPI`, or a title on the build's own disable-NVAPI list; `PROTON_FORCE_NVAPI` does not lift it)                                                                                                                                                                                                                                                                                                                                                                               | both             |
| `enable_proton_dxvk_lowlatency` / `disable_proton_dxvk_lowlatency` | `PROTON_DXVK_LOWLATENCY` 1 / 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | CachyOS only     |
| `enable_proton_vkd3d_heap` / `disable_proton_vkd3d_heap`           | `VKD3D_CONFIG` `descriptor_heap` token on / off                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | both             |
| `enable_proton_xess` / `disable_proton_xess`                       | `PROTON_XESS_UPGRADE` 1 / 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | both             |
| `enable_proton_dxvk_d3d8` / `disable_proton_dxvk_d3d8`             | `PROTON_DXVK_D3D8` 1 / 0                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | both             |
| `enable_proton_hdr` / `disable_proton_hdr`                         | `DXVK_HDR` + `DXVK_NO_HDR` 1/0 / 0/1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | both (see below) |

The CachyOS-only helpers go through `_require_proton_cachyos`, which warns and
skips the export when the tool path (`COMPAT_TOOL_PATH`) does not contain
`cachyos` in any case; the launch goes on. Enabling `PROTON_DXVK_LOWLATENCY` on
CachyOS installs that build's `dxvk-low-latency` DXVK in place of the stock one
(a non-zero `PROTON_DXVK_SAREK` wins, as does the Sarek DXVK the build turns on
by itself when the primary GPU lacks Vulkan 1.3 with `descriptorIndexing`,
unless `PROTON_DXVK_SAREK=0`), sets `DXVK_ASYNC=0` with
`dxvk.enableAsync=False`, and turns on its `dxvkllasync` tuning: DXVK compiler
threads at the CPU count minus two (minus one on 3–4 CPUs, all of them on 1–2)
and the graphics pipeline library on `Auto`. The vkd3d-heap helpers edit the
comma-separated `VKD3D_CONFIG` list in place, keeping the tokens it already
holds (launch options, an earlier layer); Proton appends
`force_bindless_texel_buffer` after the configs run, and only when
`STEAM_COMPAT_CONFIG` or `PROTON_ADD_CONFIG` names `vkd3dbindlesstb`.

| Function                                         | Exports                                                                                                                                                                                                                                                                               |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `enable_nvidia_gpu` / `disable_nvidia_gpu`       | `PROTON_FORCE_NVAPI` + `PROTON_HIDE_NVIDIA_GPU` 1/0 / 0/1; `PROTON_FORCE_NVAPI=1` makes both builds export `DXVK_NVAPI_ALLOW_OTHER_DRIVERS=1`, `DXVK_NVAPI_DRIVER_VERSION=99999` and `WINE_HIDE_AMD_GPU=1` whatever the GPU, so an NVIDIA host calls it in its `<profile>.local.conf` |
| `enable_intel_gpu` / `disable_intel_gpu`         | `PROTON_HIDE_INTEL_GPU` 0 / 1; 0 also shows the iGPU to a title the build hides it from (both builds' own list)                                                                                                                                                                       |
| `enable_smooth_motion` / `disable_smooth_motion` | `NVPRESENT_ENABLE_SMOOTH_MOTION` 1 / 0                                                                                                                                                                                                                                                |
| `enable_dlss_indicator`                          | `PROTON_DLSS_INDICATOR=1` + `DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS=DLSSIndicator=1024,DLSSGIndicator=2,`                                                                                                                                                                                   |
| `enable_dlss_override`                           | `PROTON_DLSS_UPGRADE`, plus `DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION` / `..._RR_...` with a preset                                                                                                                                                                |
| `enable_steam_deck` / `disable_steam_deck`       | `SteamDeck` 1 / 0 (handheld spoof, read by the game and both Proton builds; a title's protonfixes can force 1 over it, see `PROTONFIXES_DISABLE`)                                                                                                                                     |

`enable_dlss_override` is overloaded on its arguments, in two branches:

- **A lone letter** (`enable_dlss_override k`) applies the SR preset and exports
  `PROTON_DLSS_UPGRADE=0`, so the preset lands while the DLL upgrade stays off.
  A second letter on this branch is the RR preset.
- **Anything else** is the DLSS version (`latest` → `1`, and the no-argument
  call means `latest`); a letter after it is the SR preset and a further letter
  the RR preset.

Choosing an SR preset always sets the RR override too: it takes the explicit RR
letter when one is given, and `render_preset_latest` otherwise.

### `helpers/wine.sh`: Wine prefix commands and registry

| Function                      | Purpose                                                                                                                                                                                                                                                                                                                                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `execute_prefix_command`      | Run a command inside `WINEPREFIX` with wine on `PATH`                                                                                                                                                                                                                                                                                                                                            |
| `execute_prefix_command_once` | `<name> <command>...`: the same, gated by a `${WINEPREFIX}/.<name>` flag file; logs an error on failure                                                                                                                                                                                                                                                                                          |
| `execute_prefix_wine`         | `<name> <program> [<argument>...]`: run a program once; `.bat`/`.cmd` are stripped of their bare `pause` lines (`@pause` and `pause >nul` stay) into `/tmp/<name>.bat` on every call, never removed, and run via `cmd /c`; status 1, silent, without a program; a missing `.bat` or `.cmd` aborts the launch on every call, after the once-flag exists too, since the strip runs before the gate |
| `execute_prefix_winetricks`   | `<name> <verb>...`: run winetricks verbs once                                                                                                                                                                                                                                                                                                                                                    |
| `set_prefix_dpi_value`        | Write `LogPixels` (DPI, 96 without an argument) to the registry, on every call                                                                                                                                                                                                                                                                                                                   |
| `set_prefix_dpi_scale`        | Convert a percentage as a bare number (150; 100 without an argument) or a factor with a dot (1.5, 2.0; a bare 2 reads as 2%) to DPI, then `set_prefix_dpi_value`; `150%` prints an arithmetic-syntax error and writes no DPI while the launch goes on, and a comma (`1,5`) is read as the shell's comma operator and writes DPI 4                                                                |
| `set_prefix_registry_value`   | `<key> <name> <type> <data>`: write one registry value, set-once (see Caveats)                                                                                                                                                                                                                                                                                                                   |
| `set_prefix_registry_values`  | Write several `name\|type\|data` entries under one key                                                                                                                                                                                                                                                                                                                                           |

Every helper here runs through `execute_prefix_command`; a failed wine command
returns non-zero (1 from the run-once helpers), which at a config's top level
aborts the launch.

### `helpers/game.sh`: game executable, files and assets

| Function                  | Purpose                                                                                                                                                                                                                                       |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resolve_game_executable` | Parse `${command}` for the first absolute `/…/*.exe` path (any case); set `GAME_FILENAME`, `GAME_DIRECTORY`, `GAME_EXECUTABLE`                                                                                                                |
| `replace_game_executable` | Swap `GAME_EXECUTABLE` for a new path inside `${command}`; without an argument it leaves an empty `""` word in `${command}` where the executable was, and `restore_game_executable` then returns 0 but leaves that word, so pass the new path |
| `restore_game_executable` | Revert to the executable captured on the first swap; status 1, silent, when no swap came first                                                                                                                                                |

| Function             | Purpose                                                                                                                                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `symlink_directory`  | `<source> <target>`: replace the target dir with a symlink to a source dir (see Caveats)                                                                                                                    |
| `install_game_files` | `<target> <path>...`: copy files or directory contents into a target dir, skipping a missing path                                                                                                           |
| `download_game_file` | `<file> <url>...`: download via curl unless the file exists, trying each URL, with `LD_PRELOAD` and `LD_LIBRARY_PATH` removed; when every URL fails it logs an error and returns 0, leaving no partial file |

| Function                       | Purpose                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `install_d3d8to9`              | `<directory>`: download the d3d8to9 release `d3d8.dll` (`D3D8TO9_VERSION`) into a target dir (status 0 when the download fails, as `download_game_file`); the game also needs `WINEDLLOVERRIDES="d3d8.dll=n,b"`; an existing `d3d8.dll` is kept                                                                                                                         |
| `install_physx_legacy`         | Install the NVIDIA PhysX legacy runtime into the prefix, once (flag files `.physx` and `.physx_legacy`); a failure aborts the launch                                                                                                                                                                                                                                    |
| `install_pspcsdk_emulator_v11` | Copy the PsPcSdkEmulator `v1.1` `version.dll` (PSN login emulator, MPL-2.0, source at <https://github.com/LNDF/PsPcSdkEmulator>) into the game dir on every call, over any file of the same name (Sony PC ports); the game also needs `WINEDLLOVERRIDES="version.dll=n,b"`                                                                                              |
| `launch_via_rungame_bat`       | `[<exe> [<directory>]]`: generate `rungame.bat` setting `SteamAppId`/`SteamGameId` to `SCB_APPID` as the launcher detected it (the Steam id on Steam, `<provider>/<id>` elsewhere; kept once written) beside `GAME_EXECUTABLE`, or beside `<exe>` in `GAME_DIRECTORY`, a relative `<directory>` under it or an absolute one, and swap `${command}` to launch through it |

### `main.sh`: launch phases

| Function                 | Purpose                                                                                                                                                                                                                                            |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `apply_profile_defaults` | Accept `scb`, `noscope` or `gamemode`: the `SCB_AUTO_*` toggles, WOW64, NTSYNC, Proton's Wayland driver and the MangoHud files, then `disable_gamescope` (`scb`, `noscope`) or `enable_gamescope` (`gamemode`); log and return 1 on any other name |
| `load_game_configs`      | Source the game `.env` and `.local.env`, then the game config and its `.local.conf`; then unset `SCB_APPID`                                                                                                                                        |

On the desktop the `scb` and `noscope` profiles start in standalone-MangoHud
mode and a game config opts into gamescope with `enable_gamescope`. The defaults
overwrite the same variables set in the launch options: set those in a
`.local.conf` instead.

In Game Mode the launcher forces `SCB_NOSCOPE=1` before the configs and
`MANGOHUD=0` after them, but branches on `SCB_NOSCOPE` only after the configs
ran, so a config that set it to 0 would start a nested gamescope, which fails;
without the gamescope binary (`GAMESCOPE_BIN`, default `gamescope`) the launcher
also forces `SCB_NOSCOPE=1`. Anywhere else, with the gamescope binary installed,
a config calling `enable_gamescope` wins over an `SCB_NOSCOPE=1` set at launch:
the launcher still sourced `noscope.conf`, but runs gamescope.

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

- **vkd3d descriptor heaps**: the native `VK_EXT_descriptor_heap` path avoids
  Xid 109 crashes on NVIDIA Blackwell (RTX 50xx) with driver 595+. Both builds
  ship vkd3d-proton 3.1.0 and carry the extension, and both keep it opt-in
  behind the `descriptor_heap` token while NVIDIA driver bugs remain open
  upstream. Confirm which path a game took by launching with `VKD3D_DEBUG=info`
  and looking for the `VK_EXT_descriptor_heap enabled` line.
- **HDR**: both variants' `dxgi.dll` and `winewayland.so` read `DXVK_HDR` and
  `DXVK_NO_HDR`, and their `winex11.so` reads `DXVK_HDR` (GE's `DXVK_NO_HDR`
  too). GE also accepts the `PROTON_ENABLE_HDR` and `PROTON_USE_HDR` aliases,
  and its `proton` script writes over what `enable_proton_hdr` /
  `disable_proton_hdr` set: a non-zero alias (`PROTON_USE_HDR` when both are
  set) gives `DXVK_HDR=1` and leaves `DXVK_NO_HDR` as it was, an alias at zero
  gives `DXVK_HDR=0` and `DXVK_NO_HDR=1`. A non-zero `PROTON_FORCE_HDR` wins
  over both aliases: it gives `DXVK_HDR=1`, with `WAYLANDDRV_FORCE_HDR=1`.
  CachyOS reads none of them. On CachyOS the DXGI readers are the stock and
  low-latency DXVKs: the Sarek DXVK (1.14.1), which that build turns on for a
  GPU without Vulkan 1.3 `descriptorIndexing` or under `PROTON_DXVK_SAREK=1`,
  reads neither variable. On the no-gamescope path outside Game Mode, when the
  launcher detects a KDE, GNOME or (with a gamescope `-O`) wlroots desktop,
  `enable_auto_hdr` makes it export `PROTON_ENABLE_WAYLAND=1` and
  `PROTON_ENABLE_HDR=1` after the configs on every launch, whatever the
  display's HDR state, so GE forces `DXVK_HDR=1`; the profile defaults leave it
  off. With no HDR variable set, GE's DXGI detects HDR from the Wine Wayland
  output or gamescope (its `proton` script says so), and CachyOS's Wayland
  driver tags the game surface `windows_bt2100`, so the in-game HDR switch
  works (2322010, 2531310). The output surface must be HDR-capable: gamescope
  `--hdr-enabled` (see `enable_gamescope`), or the Wayland driver for the
  desktop path. On NVIDIA drivers older than `595.x.x`, also install the
  vk-hdr-layer (neither build ships it) and set its `ENABLE_HDR_WSI=1`; driver
  595 carries native Vulkan HDR and needs neither.

## Caveats

- **`set_prefix_registry_value` is set-once**: it queries the value first and
  skips the write if the value exists. Editing a value in a `.conf` after the
  first launch will not update the prefix until you delete the registry value or
  recreate the prefix. `set_prefix_registry_values` inherits this per entry.
- **`symlink_directory` is destructive**: it runs `rm -rf` on the target every
  call when the source exists. Do not point it at a directory with unrelated
  contents.
- **MangoHud merge tmpfiles accumulate**: each launch with a
  `mangohud/MangoHud.local.conf` or `presets.local.conf` creates a `mktemp` file
  in `$TMPDIR` (else `/tmp`) that is never removed; `/tmp` is tmpfs, emptied at
  reboot, and `systemd-tmpfiles-clean.timer` deletes its files older than ten
  days (`q /tmp … 10d` in `/usr/lib/tmpfiles.d/tmp.conf`).
- **Gamescope and standalone MangoHud are mutually exclusive**: do not `export
  MANGOHUD=1` in a config that calls `enable_gamescope`. For an OpenGL game
  without gamescope, prepend the `mangohud` wrapper to `command`: it preloads
  MangoHud's OpenGL shim (not for `cs2.sh` or `RiseOfTheTombRaider.sh`) and
  runs the command with `MANGOHUD=1` whatever the config exported (the
  installed 0.8.4 wrapper takes `--dlsym` as a no-op).
- **The MangoHud wrapper on a launcher command blacks out its window**: the
  Minecraft launcher started as `mangohud <launcher>` from a game config comes
  up as a black CEF window. A Vulkan game behind such a launcher (the Minecraft
  instance renders through Vulkan) gets the HUD from the profile's plain
  `MANGOHUD=1` alone, wrapper-free.
- **`SCB_PRE_COMMAND` reaches the gamescope path only**: the launcher evaluates
  it immediately before it runs gamescope, so a config running with
  `SCB_NOSCOPE=1`, the state the `scb` and `noscope` defaults apply (`gamemode`
  in Game Mode), never sees it. A command that must run before the game starts
  belongs in the game config body, which both paths source (see the registry
  writes in `games/lutris/warcraft-iii.conf`). `SCB_POST_COMMAND` sits on an
  `EXIT` trap the launcher sets after the configs ran: it runs on both paths,
  but not when a config aborts the launch.
- **Windows-partition paths**: `WINDOWS_USER_PATH` / `WINDOWS_ROAMING_PATH`
  resolve only when the dual-boot Windows partition is mounted.
  `symlink_directory` no-ops with a warning when the source is missing, so the
  game still launches.

## Variables without a helper

The launcher and both Proton builds read these; a game config sets them with a
plain `export`, and appends to `command` with `command+=`.

| Variable                               | Read by                                             | Effect                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| -------------------------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SCB_PRE_COMMAND`                      | launcher                                            | Shell snippet evaluated before gamescope starts (see Caveats)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `SCB_POST_COMMAND`                     | launcher                                            | Shell snippet evaluated when the launcher exits (see Caveats)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `SCB_NESTEDFIX`                        | launcher                                            | Steam overlay and input fix for nested gamescope; on by default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `PROTON_FSR4_UPGRADE`                  | both builds                                         | FSR4 upgrade for titles shipping an older FSR (GE's `PROTON_FSR3_UPGRADE` reaches no reader); a value other than `0` / `1` picks that FSR4 version; on by default on CachyOS, so there `1` changes nothing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `PROTON_FSR4_INDICATOR`                | both builds                                         | FSR4 debug indicator                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `MLFG_UPGRADE`                         | both builds (`amdxc64.dll`)                         | FSR4 multi-frame generation; on GE, `protonfixes` sets it to `0` when the FSR4 upgrade is off and keeps a value set here (`PROTON_MLFG_UPGRADE` reaches no reader in `GE-Proton11-12`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `DXVK_NVAPI_DRS_SETTINGS`              | both builds' `nvapi64.dll` (dxvk-nvapi)             | NVIDIA driver-profile (DRS) settings as `<setting>=<value>` pairs, a setting named by its hex id (as in `games/steam/35140.conf`) or by its name (both builds' own default, `ngx_dlss_sr_override=on,…`), applied when `nvapi64.dll` initialises: GE disables NVAPI for every title without an NVIDIA kernel driver (`nvidia`, `nouveau`, `nova`) unless `PROTON_FORCE_NVAPI=1` (`enable_nvidia_gpu`), CachyOS applies that rule only to the titles on its own list (and drops NVAPI for some others whatever the GPU) and leaves the rest to the DLL's device check; set here, it replaces whole the DLSS override defaults both builds' `protonfixes` put in it when the DLSS upgrade is on |
| `WINEDLLOVERRIDES`                     | Wine; both builds append their own entries after it | DLL load order, `<dll>=n,b` to load a DLL from the game folder first (mods, `install_d3d8to9`); the export replaces any value Lutris set                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `PROTONFIXES_DISABLE`                  | both builds' `protonfixes`                          | Skip the per-game fixes and the `-pf_*` launch-option aliases (2322010 sets it to drop their `SteamDeck=1`); CachyOS on any value, GE on a value other than `0`; both still run their upscaler upgrades                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `${command}`                           | launcher                                            | The launch command, each word wrapped in double quotes by the launcher, which the launcher `eval`s after the configs; a word a config appends with `command+=" -arg"` is split again by that `eval`, so a value holding spaces needs its own quotes inside the string                                                                                                                                                                                                                                                                                                                                                                                                                         |
