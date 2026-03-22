#!/usr/bin/env bash
# Test of scripts/main.sh: layers.

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

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
