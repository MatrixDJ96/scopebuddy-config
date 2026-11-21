# Proton builds

The ScopeBuddy and Proton builds this checkout is tested with, and where Proton-CachyOS
(CachyOS) and Proton-GE (GE) differ for the variables the helpers export.

## How it works

### Steam overlay on Wayland

GE loads its `steam-overlay-wayland` Vulkan layer when Steam preloads the overlay and
`winex11.drv` stays available, its `win32u.so` carrying the overlay bridge; CachyOS has
neither.

## Reference

### Tested versions

Update this table when ScopeBuddy or Proton is upgraded.

| Component           | Version                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------ |
| ScopeBuddy launcher | `ScopeBuddy-1.5.0-3.fc45.noarch`                                                           |
| Proton-CachyOS      | `cachyos-11.0-20261015-slr` (vkd3d-proton 3.1.0, DXVK `v3.1.1-97-ga78a467cadb22be-pcos`)   |
| Proton-GE           | `GE-Proton11-12` (vkd3d-proton 3.1.0, DXVK `v3.1.1-174-gf86377680682448-GE-Proton(dirty)`) |

Read the installed build id from `version` in each compatibility-tool directory, and the
component versions from the `vkd3d-proton` and `dxvk` DLLs those directories ship.

### CachyOS and GE

| Topic                                              | Proton-CachyOS                                                                                                                                                                  | Proton-GE                                                                                                       |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Steam overlay on Wayland                           | none: no overlay layer, no bridge                                                                                                                                               | works ([Steam overlay on Wayland](#steam-overlay-on-wayland))                                                   |
| Steam Input on Wayland                             | its source says it does not work                                                                                                                                                | seen working                                                                                                    |
| DXVK and vkd3d low latency, FFX3, FFX4             | `PROTON_DXVK_LOWLATENCY`, `PROTON_VKD3D_LOWLATENCY`, `PROTON_FFX3_UPGRADE`, `PROTON_FFX4_UPGRADE`                                                                               | CachyOS only: the helpers skip the export ([the CachyOS-only gate](../helpers/proton.md#the-cachyos-only-gate)) |
| FSR4 upgrade (`PROTON_FSR4_UPGRADE`)               | on by default, so only `disable_proton_fsr4` or a version changes anything                                                                                                      | read; GE's `PROTON_FSR3_UPGRADE` reaches no reader                                                              |
| D7VK                                               | reads `PROTON_D7VK_DDRAW`                                                                                                                                                       | reads `PROTON_USE_D7VK`                                                                                         |
| Sarek DXVK (1.14.1)                                | when the primary GPU lacks Vulkan 1.3 with `descriptorIndexing`, or under `PROTON_DXVK_SAREK=1` ([DXVK and vkd3d low latency](../helpers/proton.md#dxvk-and-vkd3d-low-latency)) | none                                                                                                            |
| HDR aliases and `PROTON_FORCE_HDR` ([HDR](hdr.md)) | none                                                                                                                                                                            | `PROTON_ENABLE_HDR`, `PROTON_USE_HDR`, `PROTON_FORCE_HDR`                                                       |
| `PROTONFIXES_DISABLE`                              | skips the fixes on any value                                                                                                                                                    | skips the fixes on a value other than `0`                                                                       |
