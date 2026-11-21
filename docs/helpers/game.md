# Game helpers

The `helpers/game.sh` helpers: the game executable, game files and bundled assets.

## How it works

### The executable

`resolve_game_executable` parses `${command}` for the first absolute `/…/*.exe` path (any case)
and sets `GAME_FILENAME`, `GAME_DIRECTORY`, `GAME_EXECUTABLE`, and `SCB_GAME_NATIVE`
([launch kind](../architecture/loading-order.md#launch-kind)).

`replace_game_executable` without an argument leaves an empty `""` word in `${command}` where
the executable was, and `restore_game_executable` then returns 0 but leaves that word, so pass
the new path. `restore_game_executable` returns status 1, silent, when no swap came first.

`launch_via_rungame_bat` generates `rungame.bat` setting `SteamAppId`/`SteamGameId` to
`SCB_APPID` as the launcher detected it (the Steam id on Steam, `<provider>/<id>` elsewhere;
kept once written). It writes it beside `GAME_EXECUTABLE`, or beside `<exe>` in
`GAME_DIRECTORY`, a relative `<directory>` under it or an absolute one, and swaps `${command}`
to launch through it.

### Files

A missing `symlink_directory` source is skipped with a warning
([a save folder is not linked](../pitfalls.md#a-save-folder-is-not-linked)).

`download_game_file` downloads via curl unless the file exists, trying each URL, with
`LD_PRELOAD` and `LD_LIBRARY_PATH` removed; when every URL fails it logs an error and returns
0, and curl removes a partial file.

### Assets

`install_d3d8to9` returns 0 when the download fails, as `download_game_file`, and keeps an
existing `d3d8.dll`; the game also needs `WINEDLLOVERRIDES="d3d8.dll=n,b"`.

`install_physx_legacy` installs once (flag files `.physx` and `.physx_legacy`); a failure
aborts the launch.

`install_pspcsdk_emulator_v11` copies the PsPcSdkEmulator `v1.1` `version.dll` (PSN login
emulator for Sony PC ports, MPL-2.0, source at <https://github.com/LNDF/PsPcSdkEmulator>) into
the game dir on every call, over any file of the same name; the game also needs
`WINEDLLOVERRIDES="version.dll=n,b"`.

## Reference

### Executable helpers

| Function                  | Purpose                                                           |
| ------------------------- | ----------------------------------------------------------------- |
| `resolve_game_executable` | Set `GAME_*` and `SCB_GAME_NATIVE` from `${command}`              |
| `replace_game_executable` | Swap `GAME_EXECUTABLE` for a new path inside `${command}`         |
| `restore_game_executable` | Revert to the executable captured on the first swap               |
| `launch_via_rungame_bat`  | `[<exe> [<directory>]]`: launch through a generated `rungame.bat` |

### File helpers

| Function             | Purpose                                                                                                                                                                          |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `symlink_directory`  | `<source> <target>`: replace the target dir with a symlink to a source dir ([a symlinked directory loses its contents](../pitfalls.md#a-symlinked-directory-loses-its-contents)) |
| `install_game_files` | `<target> <path>...`: copy files or directory contents into a target dir, skipping a missing path                                                                                |
| `download_game_file` | `<file> <url>...`: download unless the file exists                                                                                                                               |

### Asset helpers

| Function                       | Purpose                                                                                      |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| `install_d3d8to9`              | `<directory>`: download the d3d8to9 release `d3d8.dll` (`D3D8TO9_VERSION`) into a target dir |
| `install_physx_legacy`         | Install the NVIDIA PhysX legacy runtime into the prefix, once                                |
| `install_pspcsdk_emulator_v11` | Copy the PsPcSdkEmulator `version.dll` into the game dir                                     |
