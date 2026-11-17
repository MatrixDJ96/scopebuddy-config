# Variables for Proton, DXVK, vkd3d-proton and the GPU driver, VKD3D_CONFIG included.

# __proton_cachyos <variable>: 1, with a warning naming <variable>, off Proton-CachyOS.
__proton_cachyos() {
  if [[ ${COMPAT_TOOL_PATH,,} == *cachyos* ]]; then
    return 0
  fi

  scb_log_warning "${1} requires Proton-CachyOS"
  return 1
}

# _require_proton_cachyos <variable> <value>
_require_proton_cachyos() {
  if __proton_cachyos "${1}"; then
    export "${1}=${2}"
  fi
}

# __export_upgrade <variable> [<version>|latest]: none or latest is 1, the build's default.
__export_upgrade() {
  local version="${2}"

  if [[ -z ${version} || ${version,,} == "latest" ]]; then
    version=1
  fi

  export "${1}=${version}"
  scb_log "${1}: '${version}'"
}

_vkd3d_config_add() {
  local token="$1"

  if [[ ",${VKD3D_CONFIG}," != *",${token},"* ]]; then
    export VKD3D_CONFIG="${VKD3D_CONFIG:+${VKD3D_CONFIG},}${token}"
  fi
}

_vkd3d_config_remove() {
  local token="$1"
  local out="" field
  local IFS=','

  for field in ${VKD3D_CONFIG}; do
    if [[ ${field} == "${token}" ]]; then
      continue
    fi

    out="${out:+${out},}${field}"
  done

  if [[ -n ${out} ]]; then
    export VKD3D_CONFIG="${out}"
  else
    unset VKD3D_CONFIG
  fi
}

enable_proton_wow64() {
  export PROTON_USE_WOW64=1
}

disable_proton_wow64() {
  export PROTON_USE_WOW64=0
}

enable_proton_ntsync() {
  export PROTON_NO_FSYNC=1
  export PROTON_NO_NTSYNC=0
}

disable_proton_ntsync() {
  export PROTON_NO_FSYNC=0
  export PROTON_NO_NTSYNC=1
}

enable_proton_wayland() {
  export PROTON_ENABLE_WAYLAND=1
}

disable_proton_wayland() {
  __proton_wayland_suspended=""
  export PROTON_ENABLE_WAYLAND=0
}

enable_proton_dxvk_lowlatency() {
  _require_proton_cachyos "PROTON_DXVK_LOWLATENCY" 1
}

disable_proton_dxvk_lowlatency() {
  _require_proton_cachyos "PROTON_DXVK_LOWLATENCY" 0
}

enable_proton_vkd3d_lowlatency() {
  _require_proton_cachyos "PROTON_VKD3D_LOWLATENCY" 1
}

disable_proton_vkd3d_lowlatency() {
  _require_proton_cachyos "PROTON_VKD3D_LOWLATENCY" 0
}

enable_proton_vkd3d_heap() {
  _vkd3d_config_add descriptor_heap
}

disable_proton_vkd3d_heap() {
  _vkd3d_config_remove descriptor_heap
}

enable_proton_dxvk_d3d8() {
  export PROTON_DXVK_D3D8=1
}

disable_proton_dxvk_d3d8() {
  export PROTON_DXVK_D3D8=0
}

# CachyOS reads PROTON_D7VK_DDRAW, GE PROTON_USE_D7VK.
enable_proton_d7vk() {
  export PROTON_D7VK_DDRAW=1
  export PROTON_USE_D7VK=1
}

disable_proton_d7vk() {
  export PROTON_D7VK_DDRAW=0
  export PROTON_USE_D7VK=0
}

enable_proton_hdr() {
  export DXVK_HDR=1
  export DXVK_NO_HDR=0
}

disable_proton_hdr() {
  export DXVK_HDR=0
  export DXVK_NO_HDR=1
}

# enable_dlss_override [<version>|latest|<sr>] [<sr>|<rr>] [<rr>]: a lone letter is the SR preset.
enable_dlss_override() {
  local sr_preset=""
  local rr_preset=""

  if [[ ${1} =~ ^[A-Za-z]$ ]]; then
    set -- 0 "$@"
  fi

  if [[ ${2} =~ ^[A-Za-z]$ ]]; then
    sr_preset="render_preset_${2,,}"
    rr_preset="render_preset_latest"

    if [[ ${3} =~ ^[A-Za-z]$ ]]; then
      rr_preset="render_preset_${3,,}"
    fi
  fi

  __export_upgrade PROTON_DLSS_UPGRADE "${1}"

  if [[ -n ${sr_preset} ]]; then
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION="${sr_preset}"
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION="${rr_preset}"
    scb_log "DLSS presets: SR '${sr_preset}', RR '${rr_preset}'"
  fi
}

disable_dlss_override() {
  export PROTON_DLSS_UPGRADE=0
  unset DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION
  unset DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION
}

enable_dlss_indicator() {
  export PROTON_DLSS_INDICATOR=1
  export DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS="DLSSIndicator=1024,DLSSGIndicator=2,"
}

disable_dlss_indicator() {
  export PROTON_DLSS_INDICATOR=0
  unset DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS
}

# enable_proton_xess [<version>|latest]
enable_proton_xess() {
  __export_upgrade PROTON_XESS_UPGRADE "${1}"
}

disable_proton_xess() {
  export PROTON_XESS_UPGRADE=0
}

# enable_proton_fsr4 [<version>|latest]
enable_proton_fsr4() {
  __export_upgrade PROTON_FSR4_UPGRADE "${1}"
}

disable_proton_fsr4() {
  export PROTON_FSR4_UPGRADE=0
}

# enable_proton_ffx3 [<version>|latest]
enable_proton_ffx3() {
  if __proton_cachyos PROTON_FFX3_UPGRADE; then
    __export_upgrade PROTON_FFX3_UPGRADE "${1}"
  fi
}

disable_proton_ffx3() {
  _require_proton_cachyos "PROTON_FFX3_UPGRADE" 0
}

# enable_proton_ffx4 [<version>|latest]
enable_proton_ffx4() {
  if __proton_cachyos PROTON_FFX4_UPGRADE; then
    __export_upgrade PROTON_FFX4_UPGRADE "${1}"
  fi
}

disable_proton_ffx4() {
  _require_proton_cachyos "PROTON_FFX4_UPGRADE" 0
}

enable_nvidia_gpu() {
  export PROTON_FORCE_NVAPI=1
  export PROTON_HIDE_NVIDIA_GPU=0
}

disable_nvidia_gpu() {
  export PROTON_FORCE_NVAPI=0
  export PROTON_HIDE_NVIDIA_GPU=1
}

enable_intel_gpu() {
  export PROTON_HIDE_INTEL_GPU=0
}

disable_intel_gpu() {
  export PROTON_HIDE_INTEL_GPU=1
}

enable_proton_vkreflex() {
  export DXVK_NVAPI_VKREFLEX=1
}

disable_proton_vkreflex() {
  export DXVK_NVAPI_VKREFLEX=0
}

enable_smooth_motion() {
  export NVPRESENT_ENABLE_SMOOTH_MOTION=1
}

disable_smooth_motion() {
  export NVPRESENT_ENABLE_SMOOTH_MOTION=0
}

enable_steam_deck() {
  export SteamDeck=1
}

disable_steam_deck() {
  export SteamDeck=0
}
