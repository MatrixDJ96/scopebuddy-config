# HDR

Which variables turn HDR on for a game, who reads them in each Proton build, and what the
output surface needs.

## How it works

### Readers

Both builds' `dxgi.dll` and `winewayland.so` read `DXVK_HDR` and `DXVK_NO_HDR`
(`enable_proton_hdr` / `disable_proton_hdr`), and their `winex11.so` reads `DXVK_HDR` (GE's
`DXVK_NO_HDR` too). On CachyOS the DXGI readers are the stock and low-latency DXVKs: the Sarek
DXVK reads neither variable ([CachyOS and GE differences](builds.md#cachyos-and-ge)).

### GE aliases

GE also accepts the `PROTON_ENABLE_HDR` and `PROTON_USE_HDR` aliases, and its `proton` script
writes over what `enable_proton_hdr` / `disable_proton_hdr` set: a non-zero alias
(`PROTON_USE_HDR` when both are set) gives `DXVK_HDR=1` and leaves `DXVK_NO_HDR` as it was, an
alias at zero gives `DXVK_HDR=0` and `DXVK_NO_HDR=1`. A non-zero `PROTON_FORCE_HDR` wins over
both aliases: it forces `DXVK_HDR=1` and `WAYLANDDRV_FORCE_HDR=1` for a compositor that reports
an SDR output. CachyOS reads none of them.

### Launcher auto HDR

On the gamescope path, `enable_auto_hdr` makes the launcher add `--hdr-enabled` when a KDE or
GNOME display is in HDR.

On the no-gamescope path outside Game Mode, when the launcher detects a KDE, GNOME or (with a
gamescope `-O`) wlroots desktop, `enable_auto_hdr` makes it export `PROTON_ENABLE_WAYLAND=1`
and `PROTON_ENABLE_HDR=1` after the configs on every launch, whatever the display's HDR state,
so GE forces `DXVK_HDR=1`; the profile defaults leave it off.

### Detection without variables

With no HDR variable set, GE's DXGI detects HDR from the Wine Wayland output or gamescope (its
`proton` script says so), and CachyOS's Wayland driver tags the game surface `windows_bt2100`,
so the in-game HDR switch works (AppIDs 2322010 and 2531310).

### Output surface

The output surface must be HDR-capable: gamescope `--hdr-enabled` (`enable_gamescope`,
[gamescope helpers](../helpers/gamescope.md)), or the Wayland driver for the desktop path. On
NVIDIA drivers older than `595.x.x`, also install the vk-hdr-layer (neither build ships it) and
set its `ENABLE_HDR_WSI=1`; driver 595 carries native Vulkan HDR and needs neither.
