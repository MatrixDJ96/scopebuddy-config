# Proton helpers

The `helpers/proton.sh` helpers: Proton, DXVK, vkd3d-proton, upscaler and GPU variables.

## Sections

- How it works: the CachyOS-only gate · upscaler upgrades · sync · Wayland and Steam Input ·
  Reflex · DXVK low latency · vkd3d descriptor heaps · NVIDIA GPU · Intel GPU and Steam Deck ·
  D7VK · DLSS override and indicator
- Reference: Proton, DXVK and vkd3d · GPU, DLSS and Steam Deck

## How it works

How the two Proton builds differ for each variable:
[CachyOS and GE differences](../proton/builds.md).

### The CachyOS-only gate

The CachyOS-only helpers warn and skip the export when the tool path (`COMPAT_TOOL_PATH`) does
not contain `cachyos` in any case; the launch goes on.

### Upscaler upgrades

The upscaler upgrades (`enable_proton_xess`, `enable_proton_fsr4`, `enable_proton_ffx3`,
`enable_proton_ffx4`, `enable_dlss_override`) share one version rule: no argument, `latest` or
`1` exports `1`, the build's default version; `0` exports `0` (the upgrade off), and any other
value names the version protonfixes downloads; each logs the value it exports.

`enable_proton_fsr4` upgrades FSR for titles shipping an older FSR; how the builds' defaults
differ: [CachyOS and GE differences](../proton/builds.md#cachyos-and-ge).

`enable_proton_ffx3` makes protonfixes download the FidelityFX SDK FSR 3.1 DLLs
(`amd_fidelityfx_vk.dll`, `amd_fidelityfx_dx12.dll`) at launch; `enable_proton_ffx4` the
FidelityFX SDK FSR 4 DX12 DLLs (upscaler, frame generation, loader).

### Sync

`enable_proton_ntsync` turns FSYNC off and leaves NTSYNC on, so a kernel with `/dev/ntsync`
runs NTSYNC and one without it Wine's server-side sync (both builds' `wineserver` read
`PROTON_NO_NTSYNC`); `disable_proton_ntsync` turns FSYNC on and NTSYNC off.

### Wayland and Steam Input

Both builds switch to the Wayland driver only when `WAYLAND_DISPLAY` is set, and both let a
`PROTON_USE_WAYLAND` from the launch options win over `PROTON_ENABLE_WAYLAND`.

At `PROTON_NO_STEAMINPUT=1` a controller reaches the game natively (a DualSense as itself); at
0 the game gets Steam's virtual XInput pad when its Steam Input toggle is on. A game config
calls `enable_proton_steaminput` to keep Steam Input on Wayland.

### Reflex

Both builds load the Reflex layer only when the `nvidia` kernel module is loaded and NVAPI is
not disabled (`PROTON_DISABLE_NVAPI`, or a title on the build's own disable-NVAPI list;
`PROTON_FORCE_NVAPI` does not lift it).

### DXVK low latency

Enabling `PROTON_DXVK_LOWLATENCY` on CachyOS installs that build's `dxvk-low-latency` DXVK in
place of the stock one (a non-zero `PROTON_DXVK_SAREK` wins, as does the Sarek DXVK the build
turns on by itself when the primary GPU lacks Vulkan 1.3 with `descriptorIndexing`, unless
`PROTON_DXVK_SAREK=0`), sets `DXVK_ASYNC=0` with `dxvk.enableAsync=False`, and turns on its
`dxvkllasync` tuning: DXVK compiler threads at the CPU count minus two (minus one on 3–4 CPUs,
all of them on 1–2) and the graphics pipeline library on `Auto`.

`PROTON_VKD3D_LOWLATENCY=1` installs the build's `vkd3d-low-latency` vkd3d-proton in place of
the stock one, the D3D12 counterpart of `PROTON_DXVK_LOWLATENCY`.

### vkd3d descriptor heaps

The vkd3d-heap helpers edit the comma-separated `VKD3D_CONFIG` list in place, keeping the
tokens it already holds (launch options, an earlier layer); Proton appends
`force_bindless_texel_buffer` after the configs run, and only when `STEAM_COMPAT_CONFIG` or
`PROTON_ADD_CONFIG` names `vkd3dbindlesstb`.

The native `VK_EXT_descriptor_heap` path avoids Xid 109 crashes on NVIDIA Blackwell (RTX 50xx)
with driver 595+. Both builds ship vkd3d-proton 3.1.0 and carry the extension, and both keep it
opt-in behind the `descriptor_heap` token while NVIDIA driver bugs remain open upstream.
Confirm which path a game took by launching with `VKD3D_DEBUG=info` and looking for the
`VK_EXT_descriptor_heap enabled` line.

### NVIDIA GPU

`PROTON_FORCE_NVAPI=1` makes both builds export `DXVK_NVAPI_ALLOW_OTHER_DRIVERS=1`,
`DXVK_NVAPI_DRIVER_VERSION=99999` and `WINE_HIDE_AMD_GPU=1` whatever the GPU, so an NVIDIA host
calls `enable_nvidia_gpu` in its `<profile>.local.conf`.

### Intel GPU and Steam Deck

`PROTON_HIDE_INTEL_GPU=0` also shows the iGPU to a title the build hides it from (both builds'
own list).

`SteamDeck` is read by the game and both Proton builds; a title's protonfixes can force 1 over
it ([`PROTONFIXES_DISABLE`](../proton/variables.md#protonfixes)).

### D7VK

`enable_proton_d7vk` runs DirectDraw and D3D7 through D7VK's `ddraw.dll`.

### DLSS override and indicator

`enable_dlss_override` is overloaded on its arguments, in two branches:

- A lone letter (`enable_dlss_override k`) applies the SR preset and exports
  `PROTON_DLSS_UPGRADE=0`, so the preset lands while the DLL upgrade stays off. A second letter
  on this branch is the RR preset.
- Anything else is the DLSS version ([upscaler upgrades](#upscaler-upgrades)); a letter after
  it is the SR preset and a further letter the RR preset.

Choosing an SR preset always sets the RR override too: it takes the explicit RR letter when one
is given, and `render_preset_latest` otherwise. The presets go in
`DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION` and
`DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION`; `disable_dlss_override` exports
`PROTON_DLSS_UPGRADE=0` and unsets both.

`enable_dlss_indicator` sets
`DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS=DLSSIndicator=1024,DLSSGIndicator=2,`.

## Reference

### Proton, DXVK and vkd3d

| Function                                                             | Exports                                                        | Builds       |
| -------------------------------------------------------------------- | -------------------------------------------------------------- | ------------ |
| `enable_proton_wow64` / `disable_proton_wow64`                       | `PROTON_USE_WOW64` 1 / 0                                       | both         |
| `enable_proton_ntsync` / `disable_proton_ntsync`                     | `PROTON_NO_FSYNC` + `PROTON_NO_NTSYNC` 1/0 / 0/1               | both         |
| `enable_proton_wayland` / `disable_proton_wayland`                   | `PROTON_ENABLE_WAYLAND` 1 / 0                                  | both         |
| `enable_proton_steaminput` / `disable_proton_steaminput`             | `PROTON_NO_STEAMINPUT` 0 / 1                                   | both         |
| `enable_proton_vkreflex` / `disable_proton_vkreflex`                 | `DXVK_NVAPI_VKREFLEX` 1 / 0                                    | both         |
| `enable_proton_dxvk_lowlatency` / `disable_proton_dxvk_lowlatency`   | `PROTON_DXVK_LOWLATENCY` 1 / 0                                 | CachyOS only |
| `enable_proton_vkd3d_lowlatency` / `disable_proton_vkd3d_lowlatency` | `PROTON_VKD3D_LOWLATENCY` 1 / 0                                | CachyOS only |
| `enable_proton_vkd3d_heap` / `disable_proton_vkd3d_heap`             | `VKD3D_CONFIG` `descriptor_heap` token on / off                | both         |
| `enable_proton_xess` / `disable_proton_xess`                         | `PROTON_XESS_UPGRADE` `<version>` / 0                          | both         |
| `enable_proton_fsr4` / `disable_proton_fsr4`                         | `PROTON_FSR4_UPGRADE` `<version>` / 0                          | both         |
| `enable_proton_dxvk_d3d8` / `disable_proton_dxvk_d3d8`               | `PROTON_DXVK_D3D8` 1 / 0                                       | both         |
| `enable_proton_d7vk` / `disable_proton_d7vk`                         | `PROTON_D7VK_DDRAW` + `PROTON_USE_D7VK` 1 / 0                  | both         |
| `enable_proton_ffx3` / `disable_proton_ffx3`                         | `PROTON_FFX3_UPGRADE` `<version>` / 0                          | CachyOS only |
| `enable_proton_ffx4` / `disable_proton_ffx4`                         | `PROTON_FFX4_UPGRADE` `<version>` / 0                          | CachyOS only |
| `enable_proton_hdr` / `disable_proton_hdr`                           | `DXVK_HDR` + `DXVK_NO_HDR` 1/0 / 0/1 ([HDR](../proton/hdr.md)) | both         |

### GPU, DLSS and Steam Deck

| Function                                           | Exports                                                                                                |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `enable_nvidia_gpu` / `disable_nvidia_gpu`         | `PROTON_FORCE_NVAPI` + `PROTON_HIDE_NVIDIA_GPU` 1/0 / 0/1                                              |
| `enable_intel_gpu` / `disable_intel_gpu`           | `PROTON_HIDE_INTEL_GPU` 0 / 1                                                                          |
| `enable_smooth_motion` / `disable_smooth_motion`   | `NVPRESENT_ENABLE_SMOOTH_MOTION` 1 / 0                                                                 |
| `enable_dlss_indicator` / `disable_dlss_indicator` | `PROTON_DLSS_INDICATOR` 1 / 0, with `DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS` set / unset                     |
| `enable_dlss_override` / `disable_dlss_override`   | `PROTON_DLSS_UPGRADE` and the SR / RR preset variables ([DLSS override](#dlss-override-and-indicator)) |
| `enable_steam_deck` / `disable_steam_deck`         | `SteamDeck` 1 / 0 (handheld spoof)                                                                     |
