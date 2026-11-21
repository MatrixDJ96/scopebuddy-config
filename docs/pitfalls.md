# Pitfalls

What makes a game config go wrong, as symptom, cause and what to do.

## A registry edit does not reach the prefix

Editing a value in a `.conf` after the first launch does not update the prefix:
`set_prefix_registry_value` is set-once, querying the value first and skipping the write if the
value exists, and `set_prefix_registry_values` inherits this per entry. Delete the registry
value or recreate the prefix.

## A symlinked directory loses its contents

`symlink_directory` runs `rm -rf` on the target every call when the source exists. Do not point
it at a directory with unrelated contents.

## MangoHud temporary files pile up

Each launch with a `mangohud/MangoHud.local.conf` or `presets.local.conf` creates a `mktemp`
file in `$TMPDIR` (else `/tmp`) that is never removed. `/tmp` is tmpfs, emptied at reboot, and
`systemd-tmpfiles-clean.timer` deletes its files older than ten days (`q /tmp … 10d` in
`/usr/lib/tmpfiles.d/tmp.conf`). Nothing to do: the files go at the next reboot or after ten
days.

## Gamescope and standalone MangoHud together

Gamescope and standalone MangoHud are mutually exclusive: do not `export MANGOHUD=1` in a
config that calls `enable_gamescope`. For an OpenGL game without gamescope, prepend the
`mangohud` wrapper to `command`: it preloads MangoHud's OpenGL shim (not on a command line
containing `cs2.sh` or `RiseOfTheTombRaider.sh`) and runs the command with `MANGOHUD=1`
whatever the config exported (the installed 0.8.4 wrapper takes `--dlsym` as a no-op).

## A game launcher's window turns black

The Minecraft launcher started as `mangohud <launcher>` from a game config comes up as a black
CEF window: the MangoHud wrapper on a launcher command blacks out its window. A Vulkan game
behind such a launcher (the Minecraft instance renders through Vulkan) gets the HUD from the
profile's plain `MANGOHUD=1` alone, wrapper-free.

## `SCB_PRE_COMMAND` runs only with gamescope

The launcher evaluates `SCB_PRE_COMMAND` immediately before it runs gamescope, so a config
running with `SCB_NOSCOPE=1`, the state the `scb` and `noscope` defaults apply (`gamemode` in
Game Mode), never sees it. A command that must run before the game starts belongs in the game
config body, which both paths source (see the registry writes in
`games/lutris/warcraft-iii.conf`). `SCB_POST_COMMAND` sits on an `EXIT` trap the launcher sets
after the configs ran: it runs on both paths, but not when a config aborts the launch.

## A save folder is not linked

`WINDOWS_USER_PATH` / `WINDOWS_ROAMING_PATH` resolve only when the dual-boot Windows partition
is mounted at `/run/media/$USER/Windows`. `symlink_directory` no-ops with a warning when the
source is missing, so the game still launches; mount the partition and launch again.
