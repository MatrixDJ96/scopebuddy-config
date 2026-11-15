#!/usr/bin/env bash
# Test of scripts/constants.sh.

# shellcheck source=lib.sh
source "$(dirname "$(realpath "$0")")/lib.sh"

test_assets_are_real_files() {
  local asset

  for asset in "$PHYSX_LEGACY_BINARY" "$PSPCSDK_EMULATOR_PATH/version.dll"; do
    check_status "${asset##*/} is not an LFS pointer" 1 grep -q '^version https://git-lfs' "$asset"
  done
}

test_shipped_directories() {
  check_status "MangoHud.conf under MANGOHUD_PATH" 0 test -f "$MANGOHUD_PATH/MangoHud.conf"
}

run_tests
