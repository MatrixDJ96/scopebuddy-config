# ScopeBuddy docs

Index of the docs: each line says when to read its file.

## Architecture

- [Loading order](architecture/loading-order.md): read before choosing which file a value goes
  in, or changing the profile defaults and the launch phases.
- [Framework](architecture/framework.md): read before adding a module, a constant, a global or
  a log line, or to find where a file lives.

## Helpers

- [Launcher](helpers/launcher.md): read before setting an `SCB_AUTO_*` toggle.
- [Gamescope](helpers/gamescope.md): read before switching gamescope on or off, adding a flag,
  capping the framerate or changing the MangoHud files.
- [Proton](helpers/proton.md): read before calling a Proton, DXVK, vkd3d, upscaler or GPU
  helper.
- [Wine](helpers/wine.md): read before running a command in the prefix or writing the registry.
- [Game](helpers/game.md): read before swapping the executable, copying or downloading game
  files, or installing a bundled asset.

## Proton

- [Builds](proton/builds.md): read before upgrading Proton or ScopeBuddy, or relying on a
  variable one build alone reads.
- [HDR](proton/hdr.md): read before turning HDR on for a game.
- [Variables](proton/variables.md): read before exporting a variable no helper sets.

## How-to

- [Add a game](how-to/add-a-game.md): read before writing a game config.

## Pitfalls

- [Pitfalls](pitfalls.md): read when a config does not do what it says.
