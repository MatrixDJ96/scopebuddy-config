# Wine helpers

The `helpers/wine.sh` helpers: commands run inside the Wine prefix and registry writes.

## How it works

Every helper here runs through `execute_prefix_command`; a failed wine command returns non-zero
(1 from the run-once helpers), which at a config's top level aborts the launch.

`execute_prefix_wine` strips a `.bat` or `.cmd` of its bare `pause` lines (`@pause` and
`pause >nul` stay) into `/tmp/<name>.bat` on every call, never removed, and runs it via
`cmd /c`. It returns status 1, silent, without a program. A missing `.bat` or `.cmd` aborts the
launch on every call, after the once-flag exists too, since the strip runs before the gate.

`set_prefix_dpi_scale` takes a percentage as a bare number (150; 100 without an argument) or a
factor with a dot (1.5, 2.0; a bare 2 reads as 2%). `150%` prints an arithmetic-syntax error
and writes no DPI while the launch goes on, and a comma (`1,5`) is read as the shell's comma
operator and writes DPI 4.

## Reference

| Function                      | Purpose                                                                                                                                 |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `execute_prefix_command`      | Run a command inside `WINEPREFIX` with wine on `PATH`                                                                                   |
| `execute_prefix_command_once` | `<name> <command>...`: the same, gated by a `${WINEPREFIX}/.<name>` flag file; logs an error on failure                                 |
| `execute_prefix_wine`         | `<name> <program> [<argument>...]`: run a program once                                                                                  |
| `execute_prefix_winetricks`   | `<name> <verb>...`: run winetricks verbs once                                                                                           |
| `set_prefix_dpi_value`        | Write `LogPixels` (DPI, 96 without an argument) to the registry, on every call                                                          |
| `set_prefix_dpi_scale`        | Convert a percentage or a factor to DPI, then `set_prefix_dpi_value`                                                                    |
| `set_prefix_registry_value`   | `<key> <name> <type> <data>`: write one registry value, set-once ([pitfalls](../pitfalls.md#a-registry-edit-does-not-reach-the-prefix)) |
| `set_prefix_registry_values`  | Write several `name\|type\|data` entries under one key                                                                                  |
