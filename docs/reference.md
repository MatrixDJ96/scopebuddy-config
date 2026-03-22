# Reference

Helper functions exposed by the bash framework in `scripts/`, which the game
configs in `games/` call.

See [`../README.md`](../README.md) for the overall layout and for how to add a
game config.

Contents: Loading order · Constants (`constants.sh`) · Globals (`globals.sh`) ·
Functions · Proton variant support · Variables without a helper.

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

## Globals (`globals.sh`)

| Global                                           | Value                                                                                                                                                                                                       |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `COMPAT_TOOL_PATH`                               | first `STEAM_COMPAT_TOOL_PATHS` entry, else `PROTONPATH`                                                                                                                                                    |

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

### `helpers/game.sh`: game executable

| Function                  | Purpose                                                                                                                                                                                                                                       |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resolve_game_executable` | Parse `${command}` for the first absolute `/…/*.exe` path (any case); set `GAME_FILENAME`, `GAME_DIRECTORY`, `GAME_EXECUTABLE`                                                                                                                |
| `replace_game_executable` | Swap `GAME_EXECUTABLE` for a new path inside `${command}`; without an argument it leaves an empty `""` word in `${command}` where the executable was, and `restore_game_executable` then returns 0 but leaves that word, so pass the new path |
| `restore_game_executable` | Revert to the executable captured on the first swap; status 1, silent, when no swap came first                                                                                                                                                |

### `main.sh`: launch phases

| Function                 | Purpose                                                                                                                                                                                                                                            |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `apply_profile_defaults` | Accept `scb`, `noscope` or `gamemode`: the `SCB_AUTO_*` toggles, WOW64 and NTSYNC; log and return 1 on any other name                                                                                                                              |
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

- **vkd3d descriptor heaps**: the native `VK_EXT_descriptor_heap` path avoids
  Xid 109 crashes on NVIDIA Blackwell (RTX 50xx) with driver 595+. Both builds
  ship vkd3d-proton 3.1.0 and carry the extension, and both keep it opt-in
  behind the `descriptor_heap` token while NVIDIA driver bugs remain open
  upstream. Confirm which path a game took by launching with `VKD3D_DEBUG=info`
  and looking for the `VK_EXT_descriptor_heap enabled` line.

## Variables without a helper

The launcher and both Proton builds read these; a game config sets them with a
plain `export`, and appends to `command` with `command+=`.

| Variable                               | Read by                                             | Effect                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| -------------------------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SCB_NESTEDFIX`                        | launcher                                            | Steam overlay and input fix for nested gamescope; on by default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `PROTON_FSR4_UPGRADE`                  | both builds                                         | FSR4 upgrade for titles shipping an older FSR (GE's `PROTON_FSR3_UPGRADE` reaches no reader); a value other than `0` / `1` picks that FSR4 version; on by default on CachyOS, so there `1` changes nothing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `PROTON_FSR4_INDICATOR`                | both builds                                         | FSR4 debug indicator                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `MLFG_UPGRADE`                         | both builds (`amdxc64.dll`)                         | FSR4 multi-frame generation; on GE, `protonfixes` sets it to `0` when the FSR4 upgrade is off and keeps a value set here (`PROTON_MLFG_UPGRADE` reaches no reader in `GE-Proton11-12`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `DXVK_NVAPI_DRS_SETTINGS`              | both builds' `nvapi64.dll` (dxvk-nvapi)             | NVIDIA driver-profile (DRS) settings as `<setting>=<value>` pairs, a setting named by its hex id (as in `games/steam/35140.conf`) or by its name (both builds' own default, `ngx_dlss_sr_override=on,…`), applied when `nvapi64.dll` initialises: GE disables NVAPI for every title without an NVIDIA kernel driver (`nvidia`, `nouveau`, `nova`) unless `PROTON_FORCE_NVAPI=1` (`enable_nvidia_gpu`), CachyOS applies that rule only to the titles on its own list (and drops NVAPI for some others whatever the GPU) and leaves the rest to the DLL's device check; set here, it replaces whole the DLSS override defaults both builds' `protonfixes` put in it when the DLSS upgrade is on |
| `PROTONFIXES_DISABLE`                  | both builds' `protonfixes`                          | Skip the per-game fixes and the `-pf_*` launch-option aliases; CachyOS on any value, GE on a value other than `0`; both still run their upscaler upgrades                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `${command}`                           | launcher                                            | The launch command, each word wrapped in double quotes by the launcher, which the launcher `eval`s after the configs; a word a config appends with `command+=" -arg"` is split again by that `eval`, so a value holding spaces needs its own quotes inside the string                                                                                                                                                                                                                                                                                                                                                                                                                         |
