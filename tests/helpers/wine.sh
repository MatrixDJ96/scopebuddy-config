#!/usr/bin/env bash
# Test of scripts/helpers/wine.sh.

# shellcheck source=../lib.sh
source "$(dirname "$(realpath "$0")")/../lib.sh"

BATCH_NAME=scb-test-$$
# shellcheck disable=SC2064  # expand now: the paths are fixed here
trap "rm -rf '$TEST_ROOT' '/tmp/$BATCH_NAME.bat'" EXIT

KEY='HKEY_CURRENT_USER\Software\Some Game'

test_command_runs_once() {
  execute_prefix_command_once fonts "$COMPAT_WINE_BINARY" once >/dev/null
  execute_prefix_command_once fonts "$COMPAT_WINE_BINARY" once >/dev/null
  check_equals "run once" "wine [once]" "$(cat "$STUB_LOG")"

  check_status "a failing command" 1 execute_prefix_command_once broken false
  check_status "its flag file" 1 test -e "$WINEPREFIX/.broken"
}

test_winetricks_verbs() {
  execute_prefix_winetricks cjk arial baekmuk >/dev/null
  check_equals "winetricks" "winetricks [-q] [--force] [arial] [baekmuk]" "$(cat "$STUB_LOG")"
}

test_registry_written_only_when_absent() {
  STUB_QUERY_STATUS=0 set_prefix_registry_values "$KEY" "a|REG_DWORD|1"
  check_equals "a present value" "wine [reg] [query] [$KEY] [/v] [a]" "$(cat "$STUB_LOG")"

  : >"$STUB_LOG"
  set_prefix_registry_values "$KEY" 'b|REG_SZ|Z:\games\x y.exe' >/dev/null
  check_equals "an absent value" "wine [reg] [add] [$KEY] [/v] [b] [/t] [REG_SZ] \
[/d] [Z:\games\x y.exe] [/f]" "$(tail -n1 "$STUB_LOG")"
}

test_batch_runs_without_pause() {
  local script

  for script in setup.bat setup.cmd; do
    printf 'run.exe\r\npause\r\n  PAUSE  \nend\n' >"$SANDBOX/$script"
    rm -f "$WINEPREFIX/.$BATCH_NAME"
    : >"$STUB_LOG"
    execute_prefix_wine "$BATCH_NAME" "$SANDBOX/$script" >/dev/null
    check_equals "$script" "wine [cmd] [/c] [/tmp/$BATCH_NAME.bat]|run.exe end " \
      "$(cat "$STUB_LOG")|$(tr -d '\r' <"/tmp/$BATCH_NAME.bat" | tr '\n' ' ')"
  done
}

test_dpi() {
  set_prefix_dpi_scale 150 >/dev/null
  set_prefix_dpi_scale 1.5 >/dev/null
  set_prefix_dpi_value >/dev/null
  check_equals "LogPixels" "144 144 96" \
    "$(sed 's/.*\[\/d\] \[\([0-9]*\)\].*/\1/' "$STUB_LOG" | paste -sd ' ')"
  check_equals "LogPixels command" "wine [reg] [add] [HKEY_CURRENT_USER\Control Panel\Desktop] \
[/v] [LogPixels] [/t] [REG_DWORD] [/d] [96] [/f]" "$(tail -n1 "$STUB_LOG")"
}

test_proton_wine_first_on_path() {
  mkdir -p "$SANDBOX/system"
  write_stub "$SANDBOX/system/wine"
  check_equals "wine on PATH" "$COMPAT_WINE_BINARY" \
    "$(PATH="$SANDBOX/system:$PATH" execute_prefix_command bash -c 'command -v wine' | tail -n1)"
}

# globals.sh leaves the Steam WINEPREFIX unexported.
test_steam_prefix_reaches_command() {
  unset WINEPREFIX
  STEAM_COMPAT_DATA_PATH=$SANDBOX/compat
  source "$REPO_ROOT/scripts/globals.sh"
  check_equals "WINEPREFIX" "$SANDBOX/compat/pfx" \
    "$(execute_prefix_command printenv WINEPREFIX | tail -n1)"
}

run_tests
