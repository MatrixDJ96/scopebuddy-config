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
    echo "$PROTON_DLSS_UPGRADE ${!SR--} ${!RR--}"
  )"
}

test_dlss_override() {
  dlss_case 1 - -
  dlss_case 0 - - 0
  dlss_case 1 - - 1
  dlss_case 0 render_preset_k render_preset_latest k
  dlss_case 0 render_preset_k render_preset_j k j
  dlss_case 1 render_preset_k render_preset_latest latest k
  dlss_case 310 render_preset_k render_preset_latest 310 k
  dlss_case 1 render_preset_k render_preset_j Latest K J

  enable_dlss_override k j >/dev/null
  disable_dlss_override
  check_equals "disable_dlss_override" "0 - -" "$PROTON_DLSS_UPGRADE ${!SR--} ${!RR--}"
}

test_upgrade_versions() {
  enable_proton_xess
  check_equals "no version" 1 "$PROTON_XESS_UPGRADE"

  enable_proton_fsr4 latest
  check_equals "latest" 1 "$PROTON_FSR4_UPGRADE"

  enable_proton_fsr4
  check_equals "fsr4 no version" 1 "$PROTON_FSR4_UPGRADE"

  enable_proton_xess 2.1.0
  check_equals "a version" 2.1.0 "$PROTON_XESS_UPGRADE"

  enable_proton_fsr4 4.0.2
  check_equals "fsr4 version" 4.0.2 "$PROTON_FSR4_UPGRADE"
}

test_vkd3d_heap_token() {
  export VKD3D_CONFIG=dxr
  enable_proton_vkd3d_heap
  enable_proton_vkd3d_heap
  check_equals "token added once" dxr,descriptor_heap "$VKD3D_CONFIG"

  disable_proton_vkd3d_heap
  check_equals "token removed" dxr "$VKD3D_CONFIG"

  export VKD3D_CONFIG=dxr,descriptor_heap,pipeline_library
  disable_proton_vkd3d_heap
  check_equals "other tokens kept" dxr,pipeline_library "$VKD3D_CONFIG"
  check_equals "IFS kept" $' \t\n' "$IFS"

  unset VKD3D_CONFIG
  enable_proton_vkd3d_heap
  check_equals "token alone" descriptor_heap "$VKD3D_CONFIG"
  disable_proton_vkd3d_heap
  check_unset VKD3D_CONFIG
}

test_dxvk_lowlatency_only_on_cachyos() {
  enable_proton_dxvk_lowlatency >/dev/null
  check_unset PROTON_DXVK_LOWLATENCY

  load_framework Proton-CachyOS-slr
  enable_proton_dxvk_lowlatency
  check_equals "on CachyOS" 1 "$PROTON_DXVK_LOWLATENCY"

  disable_proton_dxvk_lowlatency
  check_equals "off on CachyOS" 0 "$PROTON_DXVK_LOWLATENCY"

  load_framework "Proton-CachyOS Latest-x86_64_v3"
  enable_proton_dxvk_lowlatency
  check_equals "on the installed build name" 1 "$PROTON_DXVK_LOWLATENCY"
}

test_ffx_only_on_cachyos() {
  enable_proton_ffx3 >/dev/null
  enable_proton_ffx4 >/dev/null
  check_unset PROTON_FFX3_UPGRADE
  check_unset PROTON_FFX4_UPGRADE

  load_framework Proton-CachyOS-slr
  enable_proton_ffx3
  enable_proton_ffx4
  check_equals "FFX3 and FFX4 default" "1 1" "$PROTON_FFX3_UPGRADE $PROTON_FFX4_UPGRADE"

  enable_proton_ffx3 3
  enable_proton_ffx4 4
  check_equals "FFX3 and FFX4 on CachyOS" "3 4" "$PROTON_FFX3_UPGRADE $PROTON_FFX4_UPGRADE"
}

run_tests
