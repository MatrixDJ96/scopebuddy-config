#!/usr/bin/env bash
# Test of scripts/helpers/gamescope.sh.

# shellcheck source=../lib.sh
source "$(dirname "$(realpath "$0")")/../lib.sh"

mode_state() {
  echo "${SCB_NOSCOPE-} ${MANGOHUD-} ${PROTON_ENABLE_WAYLAND-} [${SCB_GAMESCOPE_ARGS-}]"
}

# fake_display <primary hdr> <other hdr>: a kscreen-doctor listing the primary output last.
fake_display() {
  cat >"$KSCREEN_COMMAND" <<EOF
#!/bin/sh
if [ "\$1" != -j ]; then
  exit 1
fi
cat <<'JSON'
{"outputs": [
  {"enabled": false, "priority": 0, "hdr": true},
  {"enabled": true, "priority": 2, "hdr": $2},
  {"enabled": true, "priority": 1, "hdr": $1}
]}
JSON
EOF
  chmod +x "$KSCREEN_COMMAND"
}

test_mode_switch() {
  enable_proton_wayland
  enable_gamescope >/dev/null
  check_equals "enable_gamescope" "0 0 0 [--mangoapp -f]" "$(mode_state)"

  disable_gamescope >/dev/null
  check_equals "disable_gamescope" "1 1 1 []" "$(mode_state)"
}

test_wayland_off_stays_off() {
  disable_proton_wayland
  enable_gamescope >/dev/null
  disable_gamescope >/dev/null
  check_equals "Wayland off before gamescope" "1 1 0 []" "$(mode_state)"

  enable_proton_wayland
  enable_gamescope >/dev/null
  disable_proton_wayland
  disable_gamescope >/dev/null
  check_equals "Wayland off inside gamescope" "1 1 0 []" "$(mode_state)"
}

test_game_mode_clears_proton_values() {
  SCB_GAMEMODE=1
  export PROTON_FRAME_RATE=30 PROTON_ENABLE_WAYLAND=1
  enable_gamescope >/dev/null
  check_equals "Game Mode" "1 1 0 []" "$(mode_state)"
  check_unset PROTON_FRAME_RATE
}

test_missing_gamescope_keeps_it_off() {
  GAMESCOPE_BIN=$SANDBOX/missing
  enable_proton_wayland
  enable_gamescope >/dev/null
  check_equals "without gamescope" "1 1 1 []" "$(mode_state)"
}

test_framerate_limit() {
  set_framerate_limit 90 >/dev/null
  enable_gamescope >/dev/null
  check_equals "limit in gamescope" "[--mangoapp -f -r 90]" "[$SCB_GAMESCOPE_ARGS]"
  check_unset PROTON_FRAME_RATE

  disable_gamescope >/dev/null
  check_equals "limit without gamescope" "[] 90" "[$SCB_GAMESCOPE_ARGS] $PROTON_FRAME_RATE"

  set_framerate_limit >/dev/null
  check_equals "default limit" 60 "$PROTON_FRAME_RATE"
}

test_flags_added_once() {
  add_gamescope_flag "-b" " -w 1920 " "-b" >/dev/null
  check_equals "added" "-b -w 1920" "$SCB_GAMESCOPE_ARGS"

  remove_gamescope_flag "-b" >/dev/null
  check_equals "removed" "-w 1920" "$SCB_GAMESCOPE_ARGS"
}

test_hdr_follows_primary_output() {
  fake_display true false
  enable_gamescope >/dev/null
  check_equals "primary in HDR" "--mangoapp -f --hdr-enabled" "$SCB_GAMESCOPE_ARGS"

  disable_gamescope >/dev/null
  fake_display false true
  enable_gamescope >/dev/null
  check_equals "primary in SDR" "--mangoapp -f" "$SCB_GAMESCOPE_ARGS"

  fake_command "$KSCREEN_COMMAND" 1
  enable_gamescope >/dev/null
  check_equals "kscreen-doctor failing" "--mangoapp -f" "$SCB_GAMESCOPE_ARGS"
}

test_mangohud_files() {
  MANGOHUD_PATH=$SANDBOX/mangohud
  mkdir -p "$MANGOHUD_PATH"
  echo base=1 >"$MANGOHUD_PATH/MangoHud.conf"
  echo preset=1 >"$MANGOHUD_PATH/presets.conf"

  set_mangohud_config
  check_equals "config without a local layer" "$MANGOHUD_PATH/MangoHud.conf" "$MANGOHUD_CONFIGFILE"
  check_equals "presets without a local layer" "$MANGOHUD_PATH/presets.conf" "$MANGOHUD_PRESETSFILE"

  echo local=1 >"$MANGOHUD_PATH/MangoHud.local.conf"
  echo preset_local=1 >"$MANGOHUD_PATH/presets.local.conf"
  set_mangohud_config
  check_equals "merged config" "base=1  local=1 " "$(tr '\n' ' ' <"$MANGOHUD_CONFIGFILE")"
  check_equals "merged presets" "preset=1  preset_local=1 " \
    "$(tr '\n' ' ' <"$MANGOHUD_PRESETSFILE")"

  TMPDIR=$SANDBOX/missing set_mangohud_config 2>/dev/null
  check_equals "config when the merge fails" "$MANGOHUD_PATH/MangoHud.conf" "$MANGOHUD_CONFIGFILE"
}

run_tests
