#!/usr/bin/env bash
# Test of scripts/globals.sh.
# shellcheck disable=SC2016  # the expressions are expanded by the new shell

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

# globals_in_new_shell <expression> [<variable>=<value>]...
globals_in_new_shell() {
  env -i "${@:2}" bash -c "source '$REPO_ROOT/scripts/globals.sh' && echo \"$1\""
}

test_prefix_from_steam() {
  check_equals "WINEPREFIX under Steam" "/compat/123/pfx" \
    "$(globals_in_new_shell '$WINEPREFIX' STEAM_COMPAT_DATA_PATH=/compat/123)"
}

test_proton_paths() {
  check_equals "wine from the first Steam compat tool" "/proton/GE/files/bin/wine" \
    "$(globals_in_new_shell '$COMPAT_WINE_BINARY' STEAM_COMPAT_TOOL_PATHS=/proton/GE:/runtime)"
  check_equals "wine from PROTONPATH under Lutris" "/proton/GE/files/bin/wine" \
    "$(globals_in_new_shell '$COMPAT_WINE_BINARY' PROTONPATH=/proton/GE)"
}

test_windows_user() {
  check_equals "default Windows user" "/run/media/me/Windows/Users/MatrixDJ96" \
    "$(globals_in_new_shell '$WINDOWS_USER_PATH' USER=me)"
  check_equals "roaming folder" "/run/media/me/Windows/Users/MatrixDJ96/AppData/Roaming" \
    "$(globals_in_new_shell '$WINDOWS_ROAMING_PATH' USER=me)"
  check_equals "WINDOWS_USER set" "/run/media/me/Windows/Users/Other" \
    "$(globals_in_new_shell '$WINDOWS_USER_PATH' USER=me WINDOWS_USER=Other)"
}

run_tests
