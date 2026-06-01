# Reference

Helper functions exposed by the bash framework in `scripts/`. Game configs in
`games/` call these helpers; the launcher and Proton read the variables they
export. Function names and exported variable names are a stable contract — game
configs and external tools depend on them.

See [`../README.md`](../README.md) for the overall layout and for how to add a
game config.

## Loading order

The launcher sources one entry point (`scb.conf`, `noscope.conf` or
`gamemode.conf`). Each one runs the same three steps:

1. `source scripts/bootstrap.sh` — loads every module in dependency order.
2. `load_profile_configs "<profile>"` — applies the baseline defaults
   (`apply_default_config`), then sources the optional `<profile>.local.conf`.
3. `resolve_game_executable` and `load_game_configs` — resolve the game from the
   launch command and `SCB_APPID`, then source `games/<provider>/<id>.conf`
   followed by its optional `.local.conf`.

Effective override order, last wins:
`<profile>.conf → <profile>.local.conf → game.conf → game.local.conf`.

## Globals (`paths.sh`)

`paths.sh` defines no functions; it sets shared path globals at source time.

| Global | Value |
|---|---|
| `WINDOWS_USER` | `${WINDOWS_USER:-MatrixDJ96}` |
| `USER_CONFIG_PATH` | `${HOME}/.config` |
| `USER_DATA_PATH` | `${HOME}/.local/share` |
| `WINDOWS_USER_PATH` | `/run/media/${USER}/Windows/Users/${WINDOWS_USER}` |
| `WINDOWS_ROAMING_PATH` | `${WINDOWS_USER_PATH}/AppData/Roaming` |
| `SCOPEBUDDY_PATH` | `${SCB_CONFIGDIR:-${USER_CONFIG_PATH}/scopebuddy}` |
| `MANGOHUD_PATH`, `ASSETS_PATH`, `GAMES_PATH` | subdirs of `SCOPEBUDDY_PATH` |
| `NOPSSDK_PATH`, `PHYSX_LEGACY_BINARY` | bundled assets under `ASSETS_PATH` |
| `COMPAT_TOOL_PATH` | first `STEAM_COMPAT_TOOL_PATHS` entry, else `PROTONPATH` |
| `COMPAT_WINE_BINARY`, `COMPAT_WINETRICKS_BINARY` | tools inside `COMPAT_TOOL_PATH` |
| `WINEPREFIX`, `PREFIX_USER_PATH`, `PREFIX_ROAMING_PATH` | active Proton prefix paths |

## Functions

### `utils.sh` — logging and sourcing

| Function | Purpose | Notes |
|---|---|---|
| `scb_log` | Print a `[SCB]` log line | stdout |
| `scb_log_success` | Print a green `[SCB]` line | stdout |
| `scb_log_info` | Print a cyan `[SCB]` line | stdout |
| `scb_log_warning` | Print a yellow `[SCB]` line | stdout |
| `scb_log_error` | Print a red `[SCB]` line | stdout |
| `source_if_exists` | Source `$1` when it is a regular file | always returns 0 |

### `launcher.sh` — launcher `SCB_AUTO_*` variables

| Function | Exports |
|---|---|
| `set_auto_refresh` | `SCB_AUTO_REFRESH=$1` |
| `unset_auto_refresh` | unset `SCB_AUTO_REFRESH` |
| `set_auto_frame_limit` | `SCB_AUTO_FRAME_LIMIT=$1` |
| `unset_auto_frame_limit` | unset `SCB_AUTO_FRAME_LIMIT` |

Both variables are booleans the launcher reads, so the working call is
`set_auto_refresh 1`. On `1` the launcher detects the display and injects
gamescope `-r <detected refresh>` or `--framerate-limit <detected refresh>`. It
also sums the five `SCB_AUTO_*` flags to decide whether any auto-detection is
active, so a value other than `0` or `1` inflates that sum while the feature
itself stays off. Use `set_framerate_limit` to cap fps at a chosen number.

### `features.sh` — feature toggles

| Function | Exports |
|---|---|
| `enable_auto_res` / `disable_auto_res` | `SCB_AUTO_RES` 1 / 0 |
| `enable_auto_vrr` / `disable_auto_vrr` | `SCB_AUTO_VRR` 1 / 0 |
| `enable_auto_hdr` / `disable_auto_hdr` | `SCB_AUTO_HDR` 1 / 0 (launcher HDR auto-detection) |
| `enable_steam_deck` / `disable_steam_deck` | `SteamDeck` 1 / 0 (handheld spoof) |

### `gamescope.sh` — gamescope flags and framerate

| Function | Purpose |
|---|---|
| `add_gamescope_flag` | Append flags to `SCB_GAMESCOPE_ARGS`, skipping duplicates |
| `remove_gamescope_flag` | Remove the given flags from `SCB_GAMESCOPE_ARGS` |
| `enable_gamescope` | Gamescope mode: `MANGOHUD=0`, `SCB_NOSCOPE=0`, add `--mangoapp -f` |
| `disable_gamescope` | Standalone MangoHud: `MANGOHUD=1`, `SCB_NOSCOPE=1`, remove `--mangoapp -f` |
| `set_framerate_limit` | Cap fps; routes to gamescope `-r` or `PROTON_FRAME_RATE` per mode |

`set_framerate_limit` reads `SCB_NOSCOPE` to choose the path, so it is safe to
call before `enable_gamescope` / `disable_gamescope` — the limit is re-applied on
every mode change.

### `mangohud.sh` — MangoHud config layering

| Function | Exports |
|---|---|
| `prepare_mangohud_config` | `MANGOHUD_CONFIGFILE` (base, or base + local merged) |
| `prepare_mangohud_presets` | `MANGOHUD_PRESETSFILE` (base, or base + local merged) |
| `set_mangohud_config` | Both of the above |

### `proton.sh` — Proton / DXVK / vkd3d variables

| Function | Exports | Variant |
|---|---|---|
| `enable_proton_wow64` / `disable_proton_wow64` | `PROTON_USE_WOW64` 1 / 0 | both |
| `enable_proton_ntsync` / `disable_proton_ntsync` | `PROTON_NO_ESYNC` + `PROTON_NO_FSYNC` 1 / 0 | both |
| `enable_proton_wayland` / `disable_proton_wayland` | `PROTON_ENABLE_WAYLAND` 1 / 0 | both |
| `enable_proton_vkreflex` / `disable_proton_vkreflex` | `DXVK_NVAPI_VKREFLEX` 1 / 0 | both |
| `enable_proton_dxvk_lowlatency` / `disable_proton_dxvk_lowlatency` | `PROTON_DXVK_LOWLATENCY` 1 / 0 | CachyOS only |
| `enable_proton_vkd3d_heap` / `disable_proton_vkd3d_heap` | `VKD3D_CONFIG` `descriptor_heap` token on / off | both |
| `enable_proton_xess` / `disable_proton_xess` | `PROTON_XESS_UPGRADE` 1 / 0 | both |
| `enable_proton_dxvk_d3d8` / `disable_proton_dxvk_d3d8` | `PROTON_DXVK_D3D8` 1 / 0 | both |
| `enable_proton_hdr` / `disable_proton_hdr` | `DXVK_HDR` + `DXVK_NO_HDR` 1/0 / 0/1 | both (see below) |

`PROTON_DXVK_LOWLATENCY` is read by Proton-CachyOS alone, so its helpers are
gated by the private helper `_require_proton_cachyos`, which warns and no-ops on
other variants. Enabling it on CachyOS also turns on that build's `dxvkllasync`
tuning, which raises the DXVK compiler thread count and the graphics pipeline
library. The vkd3d-heap helpers edit the comma-separated `VKD3D_CONFIG` list in
place via `_vkd3d_config_add` / `_vkd3d_config_remove`, preserving any tokens
Proton already injected.

### `wine.sh` — Wine prefix commands and registry

| Function | Purpose |
|---|---|
| `execute_prefix_command` | Run a command inside `WINEPREFIX` with wine on `PATH` |
| `execute_prefix_command_once` | Same, gated by a `${WINEPREFIX}/.<name>` flag file |
| `execute_prefix_wine` | Run a program once; `.bat`/`.cmd` are stripped of `pause` and run via `cmd /c` |
| `execute_prefix_winetricks` | Run winetricks verbs once |
| `set_prefix_dpi_value` | Write `LogPixels` (DPI) to the registry |
| `set_prefix_dpi_scale` | Convert a percentage or factor to DPI, then `set_prefix_dpi_value` |
| `set_prefix_registry_value` | Write one registry value if it is not already set |
| `set_prefix_registry_values` | Write several `name\|type\|data` entries under one key |

### `graphics.sh` — GPU exposure and DLSS

| Function | Exports |
|---|---|
| `enable_nvidia_gpu` / `disable_nvidia_gpu` | `PROTON_FORCE_NVAPI` + `PROTON_HIDE_NVIDIA_GPU` |
| `disable_intel_gpu` | `PROTON_HIDE_INTEL_GPU=1` |
| `enable_intel_gpu` | unset `PROTON_HIDE_INTEL_GPU` |
| `enable_smooth_motion` / `disable_smooth_motion` | `NVPRESENT_ENABLE_SMOOTH_MOTION` 1 / 0, plus `NVPRESENT_LOG_LEVEL=4` on both paths |
| `enable_dlss_indicator` | `PROTON_DLSS_INDICATOR` + `DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS` |
| `enable_dlss_override` | `PROTON_DLSS_UPGRADE` (+ SR/RR render-preset overrides) |

`enable_dlss_override` is overloaded on its arguments, in two branches:

- **A lone letter** (`enable_dlss_override k`) applies the SR preset and exports
  `PROTON_DLSS_UPGRADE=0`, so the preset lands while the DLL upgrade stays off.
  A second letter on this branch is the RR preset.
- **Anything else** is the DLSS version (`latest` → `1`, and the no-argument
  call means `latest`); a following letter is the SR preset and a third letter
  the RR preset.

Choosing an SR preset always sets the RR override too: it takes the explicit RR
letter when one is given, and `render_preset_latest` otherwise. The helper logs
the three resolved values on every call.

### `game.sh` — game executable and context

| Function | Purpose |
|---|---|
| `resolve_game_executable` | Parse `${command}` for the first absolute `/…/*.exe` path; set `GAME_FILENAME`, `GAME_DIRECTORY`, `GAME_EXECUTABLE` |
| `resolve_game_context` | Map `SCB_APPID` to provider and `SCB_GAME_CONFIG` / `SCB_GAME_LOCAL_CONFIG` |
| `replace_game_executable` | Swap `GAME_EXECUTABLE` for a new path inside `${command}` |
| `restore_game_executable` | Revert to the executable captured on the first swap |

### `filesystem.sh` — files, symlinks, downloads

| Function | Purpose |
|---|---|
| `symlink_directory` | Replace a target dir with a symlink to a source dir (destructive `rm -rf`) |
| `install_game_files` | Copy files or directory contents into a target dir |
| `download_game_file` | Download via curl, trying each URL, with Steam Runtime preloads stripped |

### `assets.sh` — bundled and downloaded assets

| Function | Purpose |
|---|---|
| `install_d3d8to9` | Download the d3d8to9 native `d3d8.dll` into a target dir |
| `install_physx_legacy` | Install the NVIDIA PhysX legacy runtime into the prefix |
| `install_nopssdk_v103` | Install the NoPSSDK stub into the game dir (Sony PC ports) |
| `launch_via_rungame_bat` | Generate `rungame.bat` and swap `${command}` to launch through it |

### `profiles.sh` — profile defaults

| Function | Purpose |
|---|---|
| `apply_default_config` | Baseline toggles shared by every profile |
| `apply_profile_defaults` | Accept `scb`, `noscope` or `gamemode` and apply `apply_default_config`; log and return 1 on any other name |

The three profile names share one default set, gamescope included:
`apply_default_config` calls `disable_gamescope`, so every profile starts in
standalone-MangoHud mode and a game config opts into gamescope with
`enable_gamescope`. What distinguishes the three profiles is which
`<profile>.local.conf` gets sourced.

### `configs.sh` — config loading

| Function | Purpose |
|---|---|
| `resolve_profile_local_config` | Compute `SCB_PROFILE_LOCAL_CONFIG` for a profile |
| `load_profile_configs` | Apply profile defaults, then source the profile `.local.conf` |
| `load_game_configs` | Source the game config and its `.local.conf`, then unset `SCB_APPID` |

## Proton variant support

Tested with the versions below. Update this section when ScopeBuddy or Proton
is upgraded.

| Component | Version |
|---|---|
| ScopeBuddy launcher | `ScopeBuddy-1.4.0-2.fc44.noarch` |
| Proton-CachyOS | `cachyos-11.0-20260703-slr` (vkd3d-proton 3.1.0, DXVK 3.0.2) |
| Proton-GE | `GE-Proton11-3` (vkd3d-proton 3.1.0, DXVK 3.0.2) |

Read the installed build id from `version` in each compatibility-tool directory,
and the component versions from the `vkd3d-proton` and `dxvk` DLLs those
directories ship.

- **CachyOS-only variables** — `PROTON_DXVK_LOWLATENCY` is read by
  Proton-CachyOS alone, and its helpers warn and no-op when the active Proton is
  GE. `DXVK_NVAPI_VKREFLEX` is accepted by both builds.
- **vkd3d descriptor heaps** — the native `VK_EXT_descriptor_heap` path avoids
  Xid 109 crashes on NVIDIA Blackwell (RTX 50xx) with driver 595+. Both builds
  ship vkd3d-proton 3.1.0 and carry the extension, and both keep it opt-in
  behind the `descriptor_heap` token while NVIDIA driver bugs remain open
  upstream. `enable_proton_vkd3d_heap` adds that token to `VKD3D_CONFIG`;
  `disable_proton_vkd3d_heap` removes it, returning to the default path. Confirm
  which path a game took by launching with `VKD3D_DEBUG=info` and looking for
  the `VK_EXT_descriptor_heap enabled` line.
- **HDR** — `DXVK_HDR` is read by `dxgi.dll` on both variants and is the common
  toggle. CachyOS drives HDR inside its patched DXVK, which also honours
  `DXVK_NO_HDR`; GE accepts the `PROTON_ENABLE_HDR` and `PROTON_USE_HDR`
  aliases, which its `proton` script translates into `DXVK_HDR=1`. Since
  `DXVK_NO_HDR` belongs to the CachyOS patch, `disable_proton_hdr` turns HDR off
  through `DXVK_HDR=0` alone on GE. The output surface must be HDR-capable:
  gamescope `--hdr-enabled` through `enable_auto_hdr`, which the launcher
  appends on its KDE and GNOME detection paths, or `enable_proton_wayland` for
  the desktop path. On NVIDIA drivers older than `595.x.x`, also set
  `ENABLE_HDR_WSI=1`; driver 595 carries native Vulkan HDR and needs neither
  that variable nor the vk-hdr-layer.

## Caveats

- **`set_prefix_registry_value` is set-once** — it queries the value first and
  skips the write if any data exists. Editing a value in a `.conf` after the
  first launch will not update the prefix until you delete the registry value or
  recreate the prefix. `set_prefix_registry_values` inherits this per entry.
- **`set_prefix_dpi_value` rewrites every launch** — it calls `reg add`
  unconditionally (idempotent: the value is just re-set to the same data).
- **`symlink_directory` is destructive** — it runs `rm -rf` on the target every
  call when the source exists. Do not point it at a directory with unrelated
  contents.
- **MangoHud merge tmpfiles accumulate** — each launch with a `*.local.conf`
  override creates a `mktemp` file that is never cleaned up; the system tmpwatch
  eventually removes them.
- **Gamescope and standalone MangoHud are mutually exclusive** — `enable_gamescope`
  sets `MANGOHUD=0` and adds `--mangoapp`. Do not also `export MANGOHUD=1` in
  such a config. For an OpenGL game that needs `mangohud --dlsym` without
  gamescope, set `MANGOHUD=0` and prepend the wrapper instead (see
  `games/lutris/warsmash.conf`).
- **Windows-partition paths** — `WINDOWS_USER_PATH` / `WINDOWS_ROAMING_PATH`
  resolve only when the dual-boot Windows partition is mounted. The symlink
  helpers no-op with a warning when the source is missing, so the game still
  launches.

## Variables without a helper

The launcher and both Proton builds read these; a game config sets them with a
plain `export`.

| Variable | Read by | Effect |
|---|---|---|
| `SCB_PRE_COMMAND` / `SCB_POST_COMMAND` | launcher | Shell snippets evaluated around the game launch |
| `SCB_NESTEDFIX` | launcher | Steam overlay and input fix for nested gamescope; on by default |
| `SCB_NOSCOPE_AUTO_HDR` | launcher | HDR auto-detection on the no-gamescope path |
| `PROTON_FSR3_UPGRADE` / `PROTON_FSR4_UPGRADE` | both builds | FSR upgrade for titles shipping an older FSR |
| `PROTON_FSR4_INDICATOR` | both builds | FSR4 debug indicator |
| `PROTON_FSR4_RDNA3_UPGRADE` | GE only | FSR4 on RDNA3 hardware |
| `PROTON_MLFG_UPGRADE` | both builds | Multi-frame generation upgrade |
