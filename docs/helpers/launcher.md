# Launcher helpers

The `helpers/launcher.sh` toggles for the launcher's `SCB_AUTO_*` display features.

## How it works

`SCB_AUTO_REFRESH` and `SCB_AUTO_FRAME_LIMIT` are booleans the launcher reads. On `1` the
launcher detects the display and injects gamescope `-r <detected refresh>` or
`--framerate-limit <detected refresh>`; it tests each value with `-eq 1`, so any other value
leaves the feature off. Both act on gamescope's arguments, so on the gamescope path alone, and
`SCB_AUTO_REFRESH=1` replaces the `-r` that `set_framerate_limit` set, as `SCB_AUTO_RES=1` (a
profile default) replaces any `-W` / `-H` a config adds. Use `set_framerate_limit`
([gamescope helpers](gamescope.md)) to cap fps at a chosen number.

The launcher picks the display backend for every `SCB_AUTO_*` feature: KDE, then GNOME, then
wlroots when `jq` and `wlr-randr` are installed. On wlroots without a gamescope `-O` output it
exits with status 1, which aborts the launch, and the profile defaults turn `SCB_AUTO_RES` and
`SCB_AUTO_VRR` on. With no backend, an `SCB_AUTO_*` a config sets does nothing; one set in the
launch options makes the launcher exit 1 with an error dialog.

What `SCB_AUTO_HDR=1` makes the launcher do:
[launcher auto HDR](../proton/hdr.md#launcher-auto-hdr).

## Reference

| Function                                               | Exports                      |
| ------------------------------------------------------ | ---------------------------- |
| `enable_auto_refresh` / `disable_auto_refresh`         | `SCB_AUTO_REFRESH` 1 / 0     |
| `enable_auto_frame_limit` / `disable_auto_frame_limit` | `SCB_AUTO_FRAME_LIMIT` 1 / 0 |
| `enable_auto_res` / `disable_auto_res`                 | `SCB_AUTO_RES` 1 / 0         |
| `enable_auto_vrr` / `disable_auto_vrr`                 | `SCB_AUTO_VRR` 1 / 0         |
| `enable_auto_hdr` / `disable_auto_hdr`                 | `SCB_AUTO_HDR` 1 / 0         |
