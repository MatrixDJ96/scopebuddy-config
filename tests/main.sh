#!/usr/bin/env bash
# Test of scripts/main.sh: profiles, layers, entry points and every tracked game config.
# shellcheck disable=SC2016  # fixture layers are shell code written to files

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

# game_install: a repository copy without host .local layers, a game install, a Windows drive.
game_install() {
  CONFIG_DIR=$SANDBOX/config
  GAME_DIR="$SANDBOX/library/common/game dir"
  MODS_DIR="$SANDBOX/library/Content/Paks/~mods"
  WINDOWS=$SANDBOX/windows

  mkdir -p "$CONFIG_DIR" "$GAME_DIR" "$MODS_DIR" "$SANDBOX/bin"
  cp -r "$REPO_ROOT/scripts" "$REPO_ROOT/assets" "$REPO_ROOT/games" \
    "$REPO_ROOT/scb.conf" "$REPO_ROOT/noscope.conf" "$REPO_ROOT/gamemode.conf" "$CONFIG_DIR/"
  find "$CONFIG_DIR/games" -name '*.local.*' -delete
  touch "$GAME_DIR/Game.exe" "$GAME_DIR/d3d8.dll" "$GAME_DIR/RenderEdge_Widescreen.mix"

  for save in Zomboid "Games/Age of Mythology Retold" AppData/Roaming/Factorio; do
    mkdir -p "$WINDOWS/$save"
    echo save >"$WINDOWS/$save/save.dat"
  done

  # Linux-side folders as a first launch finds them: a swapped link would delete the Windows one.
  mkdir -p "$HOME/.local/share/Zomboid" "$HOME/.factorio" \
    "$WINEPREFIX/drive_c/users/steamuser/AppData/Roaming/Factorio" \
    "$WINEPREFIX/drive_c/users/steamuser/Games/Age of Mythology Retold"
  windows_drive "$WINDOWS"
  fake_command "$SANDBOX/bin/kscreen-doctor" 1
  # 7z x <archive> -o<dir> -y
  printf '#!/bin/sh\ncp "$2" "${3#-o}/DisableEOS.pak"\n' >"$SANDBOX/bin/7z"
  chmod +x "$SANDBOX/bin/7z"
  PATH=$SANDBOX/bin:$PATH
}

windows_drive() {
  printf '%s\n' "WINDOWS_USER_PATH='$1'" "WINDOWS_ROAMING_PATH='$1/AppData/Roaming'" \
    >"$CONFIG_DIR/scb.local.conf"
}

# launch <profile> <id> [<command>]
launch() {
  SCB_CONFIGDIR=$CONFIG_DIR
  SCB_APPID=$2
  command=${3:-"\"$GAME_DIR/Game.exe\""}
  source "$CONFIG_DIR/$1.conf"
}

# launch_game <id> [<command>]: status 1 when the config dropped the command or left a WINE*,
# PROTON*, DXVK*, VKD3D* or VKBASALT_CONFIG_FILE variable unexported, which the game would not see.
launch_game() {
  local launched=${2:-"\"$GAME_DIR/Game.exe\""}
  local unexported

  launch scb "$1" "$launched"

  if [[ $command != "$launched"* ]]; then
    return 1
  fi

  unexported=$(declare -p \
    | grep -E '^declare -[^x ]+ (WINE|PROTON|DXVK|VKD3D|VKBASALT_CONFIG_FILE)' || true)
  [[ -z $unexported ]]
}

tracked_games() {
  find "$REPO_ROOT/games" -name '*.conf' -not -name '*.local.conf' \
    | sed -E "s#^$REPO_ROOT/games/(steam/)?##; s#\\.conf\$##" | sort
}

# launch_tracked_games <label>
launch_tracked_games() {
  local game

  for game in $(tracked_games); do
    check_status "$game $1" 0 launch_game "$game"
  done

  for game in 108600 427520 rpcs3/bces00510; do
    check_status "$game native $1" 0 launch_game "$game" "\"$GAME_DIR/game.sh\""
  done
}

# fake_display: primary output at 2560x1440 60 Hz, whose top rate at that size is 143.9 Hz.
fake_display() {
  cat >"$SANDBOX/bin/kscreen-doctor" <<'EOF'
#!/bin/sh
if [ "$1" != -j ]; then
  exit 1
fi
cat <<'JSON'
{"outputs": [
  {"enabled": true, "connected": true, "priority": 2, "currentModeId": "8",
   "modes": [{"id": "8", "refreshRate": 75, "size": {"width": 2560, "height": 1440}}]},
  {"enabled": true, "connected": true, "priority": 1, "currentModeId": "1",
   "modes": [{"id": "3", "refreshRate": 165, "size": {"width": 2560, "height": 1080}},
             {"id": "1", "refreshRate": 60, "size": {"width": 2560, "height": 1440}},
             {"id": "2", "refreshRate": 143.9, "size": {"width": 2560, "height": 1440}},
             {"id": "5", "refreshRate": 100, "size": {"width": 2560, "height": 1440}}]}
]}
JSON
EOF
}

# registry_value <name>
registry_value() {
  sed -n "s/.*\[\/v\] \[$1\] \[\/t\] \[[A-Z_]*\] \[\/d\] \[\(.*\)\] \[\/f\]\$/\1/p" "$STUB_LOG"
}

test_profile_defaults() {
  local profile
  local expected

  for profile in scb noscope gamemode; do
    expected="1 1 1 1 1 1 0 m p"

    if [[ $profile == gamemode ]]; then
      expected="1 0 1 1 1 1 0 m p"
    fi

    check_equals "$profile defaults" "$expected" "$(
      if [[ $profile == gamemode ]]; then
        SCB_GAMEMODE=1
      fi
      apply_profile_defaults "$profile" >/dev/null
      echo "${SCB_NOSCOPE-} ${PROTON_ENABLE_WAYLAND-} $PROTON_USE_WOW64 $PROTON_NO_FSYNC" \
        "$SCB_AUTO_RES $SCB_AUTO_VRR $SCB_AUTO_HDR" \
        "${MANGOHUD_CONFIGFILE:+m} ${MANGOHUD_PRESETSFILE:+p}"
    )"
  done

  check_status "an unknown profile" 1 apply_profile_defaults other
}

test_layer_order() {
  local layer

  GAMES_PATH=$SANDBOX/games
  mkdir -p "$GAMES_PATH/lutris"

  for layer in env local.env conf local.conf; do
    echo "LAYERS+=\" $layer\"" >"$GAMES_PATH/lutris/g.$layer"
  done

  SCB_APPID=lutris/g
  load_game_configs >/dev/null
  check_equals "layers" " env local.env conf local.conf" "$LAYERS"
  check_unset SCB_APPID
}

test_entry_points() {
  local profile

  game_install
  echo 'SAW="$PROFILE_SAW $GAME_FILENAME $SCB_AUTO_HDR $SCB_AUTO_RES ${SCB_NOSCOPE-}"' \
    >"$CONFIG_DIR/games/lutris/g.conf"

  for profile in scb noscope gamemode; do
    echo 'export SCB_AUTO_HDR=1; PROFILE_SAW="$GAME_FILENAME $SCB_GAME_NATIVE"' \
      >"$CONFIG_DIR/$profile.local.conf"
    check_equals "$profile.conf: local layers, then game config" "Game.exe 0 Game.exe 1 1 1" "$(
      if [[ $profile == gamemode ]]; then
        SCB_GAMEMODE=1
      fi
      launch "$profile" lutris/g >/dev/null
      echo "$SAW"
    )"
    check_equals "$profile.conf native: the local layer sees it" " 1" "$(
      if [[ $profile == gamemode ]]; then
        SCB_GAMEMODE=1
      fi
      launch "$profile" lutris/g "\"$GAME_DIR/game.sh\"" >/dev/null
      echo "$PROFILE_SAW"
    )"
  done
}

test_tracked_games_launch() {
  local before

  game_install
  before=$(find "$CONFIG_DIR" "$WINDOWS" -printf '%p %s\n' | sort || true)

  launch_tracked_games launches

  check_equals "repository and Windows files changed" "" \
    "$(diff <(echo "$before") <(find "$CONFIG_DIR" "$WINDOWS" -printf '%p %s\n' | sort) || true)"
  check_equals "108600 save link" "$WINDOWS/Zomboid" "$(readlink "$HOME/.local/share/Zomboid")"
  check_status "PsPcSdk emulator in the game directory" 0 test -f "$GAME_DIR/version.dll"
}

test_factorio_links_follow_launch_kind() {
  local saves
  local roaming="$WINEPREFIX/drive_c/users/steamuser/AppData/Roaming/Factorio"

  game_install
  saves=$WINDOWS/AppData/Roaming/Factorio
  launch_game 427520
  check_equals "a Windows launch links the prefix" "$saves" "$(readlink "$roaming")"
  check_status "a Windows launch keeps ~/.factorio" 1 test -L "$HOME/.factorio"

  rm "$roaming"
  mkdir "$roaming"
  launch_game 427520 "\"$GAME_DIR/game.sh\""
  check_equals "a native launch links ~/.factorio" "$saves" "$(readlink "$HOME/.factorio")"
  check_status "a native launch keeps the prefix folder" 1 test -L "$roaming"
}

# A file where the drive should be mounted makes every mkdir under it fail.
test_tracked_games_launch_without_windows_drive() {
  game_install
  : >"$SANDBOX/unmounted"
  windows_drive "$SANDBOX/unmounted/Windows"
  cd "$GAME_DIR"
  launch_tracked_games "launches from its directory without Windows"
}

test_failing_layer_stops_launch() {
  local layer
  local profile

  game_install

  for layer in env local.env conf local.conf; do
    echo false >"$CONFIG_DIR/games/lutris/broken.$layer"
    check_status "a failing game .$layer" 1 launch scb lutris/broken
    rm "$CONFIG_DIR/games/lutris/broken.$layer"
  done

  for profile in scb noscope gamemode; do
    echo false >"$CONFIG_DIR/$profile.local.conf"
    check_status "a failing $profile.local.conf" 1 launch "$profile" lutris/g
  done
}

test_warcraft_iii_registry() {
  game_install
  fake_display
  echo 'RES_WIDTH=2560 RES_HEIGHT=1440 MAX_FPS=90' \
    >"$CONFIG_DIR/games/lutris/warcraft-iii.local.env"

  launch scb lutris/warcraft-iii >/dev/null
  check_equals "framerate and DLL override" "90 d3d8.dll=n,b" \
    "$PROTON_FRAME_RATE $WINEDLLOVERRIDES"
  check_equals "display values" "2560 1440 144 90" "$(registry_value reswidth) \
$(registry_value resheight) $(registry_value refreshrate) $(registry_value maxfps)"
  check_equals "install path" "Z:${GAME_DIR//\//\\}" "$(registry_value InstallPath)"
}

test_disable_eos_extracted() {
  game_install
  : >"$MODS_DIR/DisableEOS.7z"

  launch scb 1599660 >/dev/null
  check_status "DisableEOS.pak" 0 test -f "$MODS_DIR/DisableEOS.pak"
  check_status "its archive removed" 1 test -e "$MODS_DIR/DisableEOS.7z"
}

run_tests
