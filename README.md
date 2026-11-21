# ScopeBuddy configuration

Personal configuration for the [ScopeBuddy](https://github.com/OpenGamingCollective/ScopeBuddy)
launcher, a Steam / Lutris / Heroic launch wrapper that runs the game's command, inside
gamescope or without it. This repo holds the Bash framework and the per-game configs that
ScopeBuddy sources at launch.

## Stack

- ScopeBuddy launcher at `/usr/bin/scopebuddy`, and Proton-CachyOS or Proton-GE
  ([tested versions](docs/proton/builds.md#tested-versions)).
- Bash, sourced into the launcher's shell: no build step.
- Git LFS for `assets/`.
- Optional: a dual-boot Windows partition mounted at `/run/media/$USER/Windows` for configs
  that symlink save data
  ([a save folder is not linked](docs/pitfalls.md#a-save-folder-is-not-linked)).

## Start

1. Clone this repository to `$XDG_CONFIG_HOME/scopebuddy` (`~/.config/scopebuddy` when
   `XDG_CONFIG_HOME` is unset): the launcher reads it from there.
2. Route a game through ScopeBuddy and give it a config:
   [add a game](docs/how-to/add-a-game.md).

Before committing, run the gates in [`AGENTS.md`](AGENTS.md) § Build & run.

The rest of the docs: [`docs/README.md`](docs/README.md).
