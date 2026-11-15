#!/usr/bin/env bash
# Test of scripts/main.sh: profiles and layers.

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

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

run_tests
