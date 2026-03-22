#!/usr/bin/env bash
# Test of scripts/main.sh: profiles and layers.

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

# game_install: a repository copy without host .local layers, a game install.
game_install() {
  CONFIG_DIR=$SANDBOX/config
  GAME_DIR="$SANDBOX/library/common/game dir"
  MODS_DIR="$SANDBOX/library/Content/Paks/~mods"

  mkdir -p "$CONFIG_DIR" "$GAME_DIR" "$MODS_DIR" "$SANDBOX/bin"
  cp -r "$REPO_ROOT/scripts" "$REPO_ROOT/assets" "$REPO_ROOT/games" \
    "$REPO_ROOT/scb.conf" "$REPO_ROOT/noscope.conf" "$REPO_ROOT/gamemode.conf" "$CONFIG_DIR/"
  find "$CONFIG_DIR/games" -name '*.local.*' -delete
  touch "$GAME_DIR/Game.exe" "$GAME_DIR/d3d8.dll" "$GAME_DIR/RenderEdge_Widescreen.mix"

  fake_command "$SANDBOX/bin/kscreen-doctor" 1
  PATH=$SANDBOX/bin:$PATH
}

# launch <profile> <id> [<command>]
launch() {
  SCB_CONFIGDIR=$CONFIG_DIR
  SCB_APPID=$2
  command=${3:-"\"$GAME_DIR/Game.exe\""}
  source "$CONFIG_DIR/$1.conf"
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
  check_equals "display values" "2560 1440 144 90" "$(registry_value reswidth) \
$(registry_value resheight) $(registry_value refreshrate) $(registry_value maxfps)"
  check_equals "install path" "Z:${GAME_DIR//\//\\}" "$(registry_value InstallPath)"
}

run_tests
