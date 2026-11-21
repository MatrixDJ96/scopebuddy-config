# Variables without a helper

The variables the launcher, one or both Proton builds and the Vulkan layers read that no helper
sets: a game config sets them with a plain `export`, and appends to `command` with `command+=`.

## Sections

- How it works: the launch command · NVIDIA driver-profile settings · FSR4 multi-frame
  generation · protonfixes and its downloads · NVIDIA libraries and NVAPI · DLL overrides ·
  vkBasalt and pyroveil
- Reference: launcher · Proton · Vulkan layers

## How it works

### The launch command

`${command}` is the launch command, each word wrapped in double quotes by the launcher, which
the launcher `eval`s after the configs. A word a config appends with `command+=" -arg"` is
split again by that `eval`, so a value holding spaces needs its own quotes inside the string.

### NVIDIA driver-profile settings

`DXVK_NVAPI_DRS_SETTINGS` takes `<setting>=<value>` pairs, a setting named by its hex id (as in
`games/steam/35140.conf`) or by its name (both builds' own default,
`ngx_dlss_sr_override=on,…`), applied when `nvapi64.dll` initialises. The settings apply only
while NVAPI is on ([NVIDIA libraries and NVAPI](#nvidia-libraries-and-nvapi)). Set here, the
variable replaces whole the DLSS override defaults both builds' `protonfixes` put in it when
the DLSS upgrade is on.

### FSR4 multi-frame generation

`MLFG_UPGRADE` is read by both builds' `amdxc64.dll`. On GE, `protonfixes` sets it to `0` when
the FSR4 upgrade is off and keeps a value set here; `PROTON_MLFG_UPGRADE` reaches no reader in
`GE-Proton11-12`.

### protonfixes and its downloads

`PROTONFIXES_DISABLE` skips the per-game fixes and the `-pf_*` launch-option aliases
(`games/steam/2322010.conf` sets it to drop their `SteamDeck=1`); both builds still run their
upscaler upgrades. Which values each build accepts:
[CachyOS and GE](builds.md#cachyos-and-ge).

`PROTON_USE_OPTISCALER` downloads OptiScaler at launch and loads it as `dxgi.dll`
(`PROTON_OPTISCALER_NAME` changes the name), with the DLSS, XeSS and FSR downloads it drives; a
value other than `0` / `1` picks the version.

`PROTON_LOCAL_SHADER_CACHE` points the Mesa, AMD Vulkan, DXVK, vkd3d and NVIDIA shader caches
at the game's `steamapps/shadercache/<appid>` when Steam passes `STEAM_COMPAT_SHADER_PATH`.

### NVIDIA libraries and NVAPI

GE disables NVAPI for every title without an NVIDIA kernel driver (`nvidia`, `nouveau`, `nova`)
unless `PROTON_FORCE_NVAPI=1` (`enable_nvidia_gpu`); CachyOS applies that rule only to the
titles on its own list (and drops NVAPI for some others whatever the GPU) and leaves the rest
to the DLL's device check.

`PROTON_DISABLE_NVAPI` leaves no `nvapi64.dll` in the prefix, so no DLSS or DRS settings,
unless `PROTON_FORCE_NVAPI=1` (`enable_nvidia_gpu`) keeps it; Reflex stays off either way
([Reflex](../helpers/proton.md#reflex)).

`PROTON_NVIDIA_LIBS` and its siblings are for NVIDIA hosts only: CUDA, NVENC, NVML and OptiX
inside the prefix (`PROTON_NVIDIA_LIBS` is all four), loaded only while NVAPI is on; both
builds turn NVML on by themselves while the `nvidia` module is loaded.

### DLL overrides

`WINEDLLOVERRIDES` sets the DLL load order, `<dll>=n,b` to load a DLL from the game folder
first (mods, `install_d3d8to9`); the export replaces any value Lutris set.

### vkBasalt and pyroveil

On `ENABLE_VKBASALT=1` both builds add their bundled vkBasalt post-processing layer.

`PYROVEIL=1` adds the bundled pyroveil shader-hack layer; `PYROVEIL_CONFIG` names a
`pyroveil.json`, a relative name resolving under the build's `files/share/pyroveil/hacks/`
(every bundled hack is named for an NVIDIA driver issue).

## Reference

### Launcher

| Variable           | Effect                                                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SCB_PRE_COMMAND`  | Shell snippet evaluated before gamescope starts ([`SCB_PRE_COMMAND` runs only with gamescope](../pitfalls.md#scb_pre_command-runs-only-with-gamescope)) |
| `SCB_POST_COMMAND` | Shell snippet evaluated when the launcher exits ([`SCB_POST_COMMAND` runs on both paths](../pitfalls.md#scb_pre_command-runs-only-with-gamescope))      |
| `SCB_NESTEDFIX`    | Steam overlay and input fix for nested gamescope; on by default                                                                                         |

### Proton

| Variable                                                                                                      | Read by                                             | Effect                                                                                                   |
| ------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `PROTON_FSR4_INDICATOR`                                                                                       | both builds                                         | FSR4 debug indicator                                                                                     |
| `MLFG_UPGRADE`                                                                                                | both builds (`amdxc64.dll`)                         | FSR4 multi-frame generation ([FSR4 multi-frame generation](#fsr4-multi-frame-generation))                |
| `DXVK_NVAPI_DRS_SETTINGS`                                                                                     | both builds' `nvapi64.dll` (dxvk-nvapi)             | NVIDIA driver-profile (DRS) settings ([NVIDIA driver-profile settings](#nvidia-driver-profile-settings)) |
| `WINEDLLOVERRIDES`                                                                                            | Wine; both builds append their own entries after it | DLL load order ([DLL overrides](#dll-overrides))                                                         |
| `PROTONFIXES_DISABLE`                                                                                         | both builds' `protonfixes`                          | Skip the per-game fixes ([protonfixes and its downloads](#protonfixes-and-its-downloads))                |
| `PROTON_USE_OPTISCALER`                                                                                       | both builds' `protonfixes`                          | OptiScaler as `dxgi.dll`                                                                                 |
| `PROTON_LOCAL_SHADER_CACHE`                                                                                   | both builds' `protonfixes`                          | Per-game shader caches ([protonfixes](#protonfixes-and-its-downloads))                                   |
| `PROTON_FORCE_HDR`                                                                                            | Proton-GE                                           | Forces HDR on an SDR-reporting compositor ([HDR](hdr.md))                                                |
| `PROTON_USE_SDL` / `PROTON_PREFER_SDL`                                                                        | both builds                                         | Input through SDL: sets `PROTON_DISABLE_HIDRAW=1` and `PROTON_NO_STEAMINPUT=1`                           |
| `PROTON_DISABLE_NVAPI`                                                                                        | both builds                                         | No `nvapi64.dll` in the prefix ([NVIDIA libraries and NVAPI](#nvidia-libraries-and-nvapi))               |
| `PROTON_NVIDIA_LIBS`, `PROTON_NVIDIA_NVCUDA` / `_NVENC` / `_NVML` / `_NVOPTIX`, `PROTON_NVIDIA_LIBS_NO_32BIT` | both builds                                         | NVIDIA libraries inside the prefix                                                                       |
| `PROTON_USE_WINED3D` / `PROTON_USE_WINED3D11`                                                                 | both builds                                         | WineD3D instead of DXVK                                                                                  |
| `PROTON_NO_D3D10` / `PROTON_NO_D3D11`                                                                         | both builds                                         | D3D10 / D3D11 hidden                                                                                     |
| `PROTON_FORCE_LARGE_ADDRESS_AWARE`                                                                            | both builds                                         | Large-address-aware                                                                                      |
| `PROTON_HEAP_DELAY_FREE` / `PROTON_HEAP_ZERO_MEMORY`                                                          | both builds                                         | Heap delay-free / zero-fill                                                                              |
| `PROTON_OLD_GL_STRING`                                                                                        | both builds                                         | A pre-2003 GL extension string                                                                           |
| `PROTON_NO_WM_DECORATION`                                                                                     | both builds                                         | No window decorations                                                                                    |
| `PROTON_USE_WRITECOPY`                                                                                        | Proton-GE                                           | Simulated write-copy                                                                                     |

### Vulkan layers

| Variable                               | Read by                                           | Effect                                                                                                             |
| -------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `ENABLE_VKBASALT` / `DISABLE_VKBASALT` | Vulkan loader; both builds read `ENABLE_VKBASALT` | Turn the vkBasalt layer on / off ([vkBasalt and pyroveil](#vkbasalt-and-pyroveil))                                 |
| `VKBASALT_CONFIG_FILE`                 | vkBasalt                                          | Effect config to load; the presets live in `vkbasalt/`                                                             |
| `LOW_LATENCY_LAYER`                    | both builds                                       | Adds the bundled `VK_LAYER_KORTHOS_low_latency` Vulkan layer (`VK_AMD_anti_lag` / `VK_NV_low_latency2` on any GPU) |
| `PYROVEIL` / `PYROVEIL_CONFIG`         | both builds; the pyroveil layer                   | Bundled shader-hack layer                                                                                          |
