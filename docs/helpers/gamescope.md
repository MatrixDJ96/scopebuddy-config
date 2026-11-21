# Gamescope helpers

The `helpers/gamescope.sh` helpers: gamescope flags, the gamescope and standalone-MangoHud
modes, the framerate limit and the MangoHud files.

## How it works

### Gamescope flags

The launcher uses `SCB_GAMESCOPE_ARGS` only when the launch options pass no gamescope arguments
before `--` (unless `SCB_APPENDMODE=1`); otherwise every flag these helpers set is dropped.
Every flag helper rebuilds `SCB_GAMESCOPE_ARGS` from its own list: a value from the launch
environment is gone once the profile defaults run, and one a config assigns directly lasts only
until the next helper call, so a flag goes through `add_gamescope_flag`. A flag and its value
go in one argument (`"-w 1920"`), and `remove_gamescope_flag` matches each whole (`"-w 1920"`,
not `-w`).

### The two modes

`enable_gamescope` switches to gamescope mode: `MANGOHUD=0`, `SCB_NOSCOPE=0`, then
`PROTON_ENABLE_WAYLAND=0` and `PROTON_NO_STEAMINPUT=0` where each was the other way, and the
flags `--mangoapp -f`. It adds `--hdr-enabled` when `kscreen-doctor` reports the primary output
in HDR; that check needs `jq`, and without it the flag is never added. In Game Mode or without
the gamescope binary it warns and runs `disable_gamescope` instead
([Game Mode](../architecture/loading-order.md#game-mode-and-scb_noscope)). A config that calls
it must not export `MANGOHUD=1`
([gamescope and standalone MangoHud together](../pitfalls.md#gamescope-and-standalone-mangohud-together)).

`disable_gamescope` switches to standalone MangoHud: `MANGOHUD=1`, `SCB_NOSCOPE=1`,
`PROTON_ENABLE_WAYLAND=1` and `PROTON_NO_STEAMINPUT=1`, each again when gamescope changed it
and its own `disable_proton_wayland` or `enable_proton_steaminput` did not run since. In Game
Mode, where the game runs in Steam's gamescope, it sets those two as `enable_gamescope` sets
them. It removes `--mangoapp -f --hdr-enabled`. For an OpenGL game in this mode, see
[gamescope and standalone MangoHud together](../pitfalls.md#gamescope-and-standalone-mangohud-together).

### Framerate limit

`set_framerate_limit` reads `SCB_NOSCOPE` to choose the path, so it is safe to call before
`enable_gamescope` / `disable_gamescope`: the limit is re-applied on every mode change, and
each change first unsets `PROTON_FRAME_RATE` and strips any gamescope `-r`, so only a limit set
through `set_framerate_limit` survives it.

Without gamescope, Proton turns `PROTON_FRAME_RATE` into DXVK's `dxgi.maxFrameRate` and
`d3d9.maxFrameRate`, so the cap reaches the D3D9–D3D12 games DXVK and vkd3d-proton render (D3D8
too, under `enable_proton_dxvk_d3d8` or through `install_d3d8to9`), not OpenGL, native Vulkan
or wined3d ones, and a set `DXVK_FRAME_RATE` or `VKD3D_FRAME_RATE` wins over it.

### MangoHud files

`set_mangohud_config` exports each file as the base, or the base with its `.local` layer
merged; the base, with an error, when the merge fails. A merge leaves a temporary file
([MangoHud temporary files pile up](../pitfalls.md#mangohud-temporary-files-pile-up)).

## Reference

| Function                | Purpose                                                                          |
| ----------------------- | -------------------------------------------------------------------------------- |
| `add_gamescope_flag`    | Append flags to `SCB_GAMESCOPE_ARGS`, skipping duplicates                        |
| `remove_gamescope_flag` | Remove the given flags from `SCB_GAMESCOPE_ARGS`                                 |
| `enable_gamescope`      | Gamescope mode                                                                   |
| `disable_gamescope`     | Standalone-MangoHud mode                                                         |
| `set_framerate_limit`   | Cap fps (60 without an argument): gamescope `-r` or `PROTON_FRAME_RATE` per mode |
| `set_mangohud_config`   | Export `MANGOHUD_CONFIGFILE` and `MANGOHUD_PRESETSFILE`                          |
