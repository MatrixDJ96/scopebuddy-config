#!/usr/bin/env bash
# Test of scripts/constants.sh.

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

test_shipped_directories() {
  check_status "MangoHud.conf under MANGOHUD_PATH" 0 test -f "$MANGOHUD_PATH/MangoHud.conf"
}

run_tests
