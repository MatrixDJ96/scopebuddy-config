# Sandbox, stubs and checks shared by every test.

REPO_ROOT=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
TEST_ROOT=$(mktemp -d)
# shellcheck disable=SC2064  # expand now: the path is fixed here
trap "rm -rf '$TEST_ROOT'" EXIT

# load_framework [<proton name>]
load_framework() {
  local tool_name=${1:-GE-Proton}

  SANDBOX=$(mktemp -d -p "$TEST_ROOT")
  STUB_TOOL=$SANDBOX/$tool_name
  mkdir -p "$STUB_TOOL/files/bin" "$STUB_TOOL/protonfixes" "$SANDBOX/home" "$SANDBOX/tmp" \
    "$SANDBOX/wine prefix"
  write_stub "$STUB_TOOL/files/bin/wine"
  write_stub "$STUB_TOOL/protonfixes/winetricks"
  write_stub "$SANDBOX/gamescope"

  export STUB_LOG=$SANDBOX/calls.log
  export HOME=$SANDBOX/home
  export TMPDIR=$SANDBOX/tmp
  export WINEPREFIX="$SANDBOX/wine prefix"
  export STEAM_COMPAT_TOOL_PATHS=$STUB_TOOL:$SANDBOX/steam-linux-runtime
  export SCB_CONFIGDIR=$REPO_ROOT
  GAMESCOPE_BIN=$SANDBOX/gamescope
  KSCREEN_COMMAND=$SANDBOX/kscreen-doctor
  SCB_GAMEMODE=0

  set -eo pipefail
  # shellcheck source=../scripts/main.sh
  source "$REPO_ROOT/scripts/main.sh"
}

# write_stub <path>: logs `<name> [arg]...` to STUB_LOG; `reg query` exits STUB_QUERY_STATUS.
write_stub() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
{
  printf '%s' "${0##*/}"
  printf ' [%s]' "$@"
  echo
} >>"$STUB_LOG"

if [ "$1 $2" = "reg query" ]; then
  exit "${STUB_QUERY_STATUS:-1}"
fi
STUB
  chmod +x "$1"
}

fake_command() {
  printf '#!/bin/sh\nexit %s\n' "$2" >"$1"
  chmod +x "$1"
}

check_equals() {
  if [ "$2" = "$3" ]; then
    echo "OK: $1 = '$3'"
  else
    echo "FAIL: $1 is '$3', expected '$2'"
  fi
}

check_unset() {
  if [ -n "${!1+set}" ]; then
    echo "FAIL: $1 is set to '${!1}', expected unset"
  else
    echo "OK: $1 unset"
  fi
}

# check_status <what> <expected> <command>...: run as a background job, where errexit stays on.
check_status() {
  local status=0

  "${@:3}" >/dev/null 2>&1 &
  wait "$!" || status=$?
  check_equals "$1: status" "$2" "$status"
}

# run_tests: prints END last, which tests/run.sh requires.
run_tests() {
  local test
  local status

  for test in $(compgen -A function test_); do
    status=0
    (
      load_framework
      "$test"
    ) &
    wait "$!" || status=$?

    if [ "$status" != 0 ]; then
      echo "FAIL: $test stopped with status $status"
    fi
  done

  echo END
}
