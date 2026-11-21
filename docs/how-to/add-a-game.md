# Add a game

How to give a game its own config file and check that the launch reads it.

## How to

1. Route the game through ScopeBuddy: Steam launch options `scb -- %command%`; Lutris, the
   game's command prefix `scb --`. Without it no `[SCB]` line appears and no config is read.
2. Find the ID. Steam: the number in the store URL or on steamdb.info, saved as
   `games/steam/<appid>.conf`. Heroic and Ubisoft are auto-detected from their URI schemes;
   save under `games/heroic/<id>.conf` or `games/ubisoft/<id>.conf`. Any other launcher
   (Lutris, RPCS3) is not detected: set `SCB_APPID=<provider>/<id>` in the game's environment
   (Lutris: the game's environment variables) and save as `games/<provider>/<id>.conf`. A game
   with both a Windows and a Linux build branches on `SCB_GAME_NATIVE`, as
   `games/steam/427520.conf` does
   ([launch kind](../architecture/loading-order.md#launch-kind)).
3. Add helper calls. The existing files in `games/` are the working examples: copy the closest
   one and adjust.

   ```bash
   # <Game Title>

   # Enable Gamescope
   enable_gamescope
   ```

4. Launch the game once and read the `[SCB]` lines the framework prints on the launcher's
   stdout (Steam started from a terminal shows them): `__game_config` names the file that was
   resolved. Check it is the file you just wrote: a wrong provider or id resolves to a path
   that does not exist, and the launch continues silently with the profile defaults alone. A
   launch the launcher does not detect (Lutris without `SCB_APPID`) arrives as `null` and
   resolves to `games/steam/null.conf`.

A value that differs per machine goes in the game's `.local.env` when the config reads it, else
in its `.local.conf`
([local layers](../architecture/loading-order.md#local-layers)).
