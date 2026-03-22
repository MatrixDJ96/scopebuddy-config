#!/usr/bin/env bash
# Test of scripts/helpers/proton.sh.

# shellcheck source=../lib.sh
source "$(dirname "$(realpath "$0")")/../lib.sh"

SR=DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION
RR=DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION

# dlss_case <upgrade> <sr preset> <rr preset> [<argument>...]: "-" stands for a preset left unset.
dlss_case() {
  check_equals "enable_dlss_override ${*:4}" "$1 $2 $3" "$(
    enable_dlss_override "${@:4}" >/dev/null
    echo "$PROTON_DLSS_UPGRADE ${!SR:--} ${!RR:--}"
  )"
}

test_dlss_override() {
  dlss_case 1 - -
  dlss_case 0 render_preset_k render_preset_latest k
  dlss_case 0 render_preset_k render_preset_j k j
  dlss_case 1 render_preset_k render_preset_latest latest k
  dlss_case 310 render_preset_k render_preset_latest 310 k
}

test_vkd3d_heap_token() {
  export VKD3D_CONFIG=dxr
  enable_proton_vkd3d_heap
  enable_proton_vkd3d_heap
  check_equals "token added once" dxr,descriptor_heap "$VKD3D_CONFIG"

  disable_proton_vkd3d_heap
  check_equals "token removed" dxr "$VKD3D_CONFIG"

  unset VKD3D_CONFIG
  enable_proton_vkd3d_heap
  disable_proton_vkd3d_heap
  check_unset VKD3D_CONFIG
}

test_dxvk_lowlatency_only_on_cachyos() {
  enable_proton_dxvk_lowlatency >/dev/null
  check_unset PROTON_DXVK_LOWLATENCY

  load_framework proton-cachyos-slr
  enable_proton_dxvk_lowlatency
  check_equals "on CachyOS" 1 "$PROTON_DXVK_LOWLATENCY"
}

run_tests
