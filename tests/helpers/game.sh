#!/usr/bin/env bash
# Test of scripts/helpers/game.sh.

# shellcheck source=../lib.sh
source "$(dirname "$(realpath "$0")")/../lib.sh"

test_exe_found_in_command() {
  command='"/steam/proton" run "/games/Some Game/Game.EXE" -windowed "/games/Some Game/B.exe"'
  resolve_game_executable >/dev/null
  check_equals "executable" "/games/Some Game/Game.EXE" "$GAME_EXECUTABLE"
  check_equals "directory and name" "/games/Some Game Game.EXE" "$GAME_DIRECTORY $GAME_FILENAME"
}

test_config_paths() {
  GAMES_PATH=$SANDBOX/games
  mkdir -p "$GAMES_PATH/steam" "$GAMES_PATH/lutris"
  echo 'LOADED+=" steam"' >"$GAMES_PATH/steam/1234.conf"
  echo 'LOADED+=" lutris"' >"$GAMES_PATH/lutris/some-game.local.env"

  SCB_APPID=1234
  load_game_configs >/dev/null
  SCB_APPID=lutris/some-game
  load_game_configs >/dev/null
  check_equals "a numeric id and a provider id" " steam lutris" "$LOADED"
}

test_executable_swap_and_restore() {
  local dir

  check_status "restore before any swap" 1 restore_game_executable

  command='"/games/Game.exe"'
  resolve_game_executable >/dev/null
  replace_game_executable /games/rungame.bat >/dev/null
  restore_game_executable >/dev/null
  check_equals "restored" '"/games/Game.exe"' "$command"

  for dir in "/games/C&C" "/games/Some Game" "/games/Game [GOTY]"; do
    command="\"$dir/Game.exe\" -windowed"
    resolve_game_executable >/dev/null
    replace_game_executable "$dir/rungame.bat" >/dev/null
    check_equals "swapped in $dir" "\"$dir/rungame.bat\" -windowed" "$command"
  done
}

run_tests
