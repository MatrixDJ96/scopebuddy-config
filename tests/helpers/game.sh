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

test_symlink_directory() {
  mkdir -p "$SANDBOX/target/old" "$SANDBOX/saves"
  echo save >"$SANDBOX/saves/a.sav"

  symlink_directory "$SANDBOX/missing" "$SANDBOX/target" >/dev/null
  check_status "a missing source leaves the target" 0 test -d "$SANDBOX/target/old"

  symlink_directory "$SANDBOX/saves" "$SANDBOX/target"
  symlink_directory "$SANDBOX/saves" "$SANDBOX/target"
  check_equals "target linked twice" "$SANDBOX/saves save" \
    "$(readlink "$SANDBOX/target") $(cat "$SANDBOX/saves/a.sav")"

  symlink_directory "$SANDBOX/saves" "$SANDBOX/new/parent/target"
  check_equals "target under missing parents" "$SANDBOX/saves" \
    "$(readlink "$SANDBOX/new/parent/target")"
}

test_install_game_files() {
  mkdir -p "$SANDBOX/bundle/sub" "$SANDBOX/game/sub"
  echo new >"$SANDBOX/bundle/sub/a.txt"
  echo new >"$SANDBOX/b.txt"
  echo old >"$SANDBOX/game/sub/a.txt"

  install_game_files "$SANDBOX/game" "$SANDBOX/bundle" "$SANDBOX/b.txt"
  check_equals "copied over older files" "new new" \
    "$(cat "$SANDBOX/game/sub/a.txt" "$SANDBOX/game/b.txt" | paste -sd ' ')"
  check_status "copied, not linked" 1 test "$SANDBOX/game/sub/a.txt" -ef "$SANDBOX/bundle/sub/a.txt"
}

# A launch's LD_LIBRARY_PATH must not reach curl: a broken libcurl there would stop it.
test_download_game_file() {
  local file="$SANDBOX/new dir/file.dll"

  mkdir -p "$SANDBOX/broken-lib"
  : >"$SANDBOX/broken-lib/libcurl.so.4"
  echo first >"$SANDBOX/source.dll"
  LD_LIBRARY_PATH=$SANDBOX/broken-lib download_game_file "$file" "file://$SANDBOX/source.dll" \
    >/dev/null 2>&1
  check_equals "downloaded" first "$(cat "$file")"

  echo second >"$SANDBOX/source.dll"
  download_game_file "$file" "file://$SANDBOX/source.dll" >/dev/null 2>&1
  check_equals "a present file kept" first "$(cat "$file")"

  check_status "a failing URL" 0 download_game_file "$SANDBOX/other.dll" "file://$SANDBOX/missing"
  check_status "no file from it" 1 test -e "$SANDBOX/other.dll"
}

test_rungame_bat() {
  GAME_DIRECTORY=$SANDBOX/game
  GAME_EXECUTABLE=$GAME_DIRECTORY/Game.exe
  __game_appid=4321
  command="\"$GAME_EXECUTABLE\""
  mkdir -p "$GAME_DIRECTORY"

  launch_via_rungame_bat >/dev/null
  check_equals "rungame.bat" 'set SteamAppId=4321|set SteamGameId=4321|"Game.exe"' \
    "$(paste -sd '|' "$GAME_DIRECTORY/rungame.bat")"
  check_equals "command" "\"$GAME_DIRECTORY/rungame.bat\"" "$command"

  echo edited >"$GAME_DIRECTORY/rungame.bat"
  launch_via_rungame_bat >/dev/null
  check_equals "an existing rungame.bat kept" edited "$(cat "$GAME_DIRECTORY/rungame.bat")"
}

test_physx_order() {
  install_physx_legacy >/dev/null
  check_equals "winetricks, then msiexec" "winetricks [-q] [--force] [physx]|wine [msiexec] [/i] \
[$PHYSX_LEGACY_BINARY] [/qn]" "$(paste -sd '|' "$STUB_LOG")"

  rm -f "$WINEPREFIX"/.physx*
  fake_command "$SANDBOX/failing" 1
  COMPAT_WINETRICKS_BINARY=$SANDBOX/failing check_status "a failing winetricks" 1 \
    install_physx_legacy
}

run_tests
