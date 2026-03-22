# Variables for Proton, DXVK, vkd3d-proton and the GPU driver, VKD3D_CONFIG included.

# _require_proton_cachyos <variable> <value>
_require_proton_cachyos() {
  local var_name="$1"
  local value="$2"

  if [[ ${COMPAT_TOOL_PATH,,} == *cachyos* ]]; then
    export "${var_name}=${value}"
    return 0
  fi

  scb_log_warning "${var_name} requires Proton-CachyOS"
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

# FSYNC off: NTSYNC takes over where /dev/ntsync exists.
enable_proton_ntsync() {
  export PROTON_NO_FSYNC=1
}

disable_proton_ntsync() {
  export PROTON_NO_FSYNC=0
}

enable_proton_wayland() {
  export PROTON_ENABLE_WAYLAND=1
}

disable_proton_wayland() {
  export PROTON_ENABLE_WAYLAND=0
}

enable_proton_vkreflex() {
  export DXVK_NVAPI_VKREFLEX=1
}

disable_proton_vkreflex() {
  export DXVK_NVAPI_VKREFLEX=0
}

# Proton-CachyOS only, where it also turns on dxvkllasync.
enable_proton_dxvk_lowlatency() {
  _require_proton_cachyos "PROTON_DXVK_LOWLATENCY" 1
}

disable_proton_dxvk_lowlatency() {
  _require_proton_cachyos "PROTON_DXVK_LOWLATENCY" 0
}

# The native VK_EXT_descriptor_heap path, opt-in behind the descriptor_heap token.
enable_proton_vkd3d_heap() {
  _vkd3d_config_add descriptor_heap
}

disable_proton_vkd3d_heap() {
  _vkd3d_config_remove descriptor_heap
}

enable_proton_xess() {
  export PROTON_XESS_UPGRADE=1
}

disable_proton_xess() {
  export PROTON_XESS_UPGRADE=0
}

# D3D8 through DXVK (d3d8 -> d3d9 -> Vulkan).
enable_proton_dxvk_d3d8() {
  export PROTON_DXVK_D3D8=1
}

disable_proton_dxvk_d3d8() {
  export PROTON_DXVK_D3D8=0
}

enable_proton_hdr() {
  export DXVK_HDR=1
  export DXVK_NO_HDR=0
}

disable_proton_hdr() {
  export DXVK_HDR=0
  export DXVK_NO_HDR=1
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

# For a hybrid laptop, where a game would otherwise pick the Intel iGPU.
disable_intel_gpu() {
  export PROTON_HIDE_INTEL_GPU=1
}

enable_smooth_motion() {
  export NVPRESENT_ENABLE_SMOOTH_MOTION=1
}

disable_smooth_motion() {
  export NVPRESENT_ENABLE_SMOOTH_MOTION=0
}

enable_dlss_indicator() {
  export PROTON_DLSS_INDICATOR=1
  export DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS="DLSSIndicator=1024,DLSSGIndicator=2,"
}

# enable_dlss_override [<version>|<sr>] [<sr>|<rr>] [<rr>]: a lone letter is the SR preset.
enable_dlss_override() {
  local version
  local sr_preset=""
  local rr_preset=""

  if [[ ${1} =~ ^[A-Za-z]$ ]]; then
    set -- 0 "$@"
  fi

  version="${1:-latest}"

  if [[ ${2} =~ ^[A-Za-z]$ ]]; then
    sr_preset="render_preset_${2,,}"
    rr_preset="render_preset_latest"

    if [[ ${3} =~ ^[A-Za-z]$ ]]; then
      rr_preset="render_preset_${3,,}"
    fi
  fi

  if [[ ${version,,} == "latest" ]]; then
    version="1"
  fi

  export PROTON_DLSS_UPGRADE="${version}"

  if [[ -n ${sr_preset} ]]; then
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION="${sr_preset}"
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION="${rr_preset}"
  fi

  scb_log "DLSS: PROTON_DLSS_UPGRADE=${version}" \
    "SR=${sr_preset:-<unchanged>} RR=${rr_preset:-<unchanged>}"
}

enable_steam_deck() {
  export SteamDeck=1
}

disable_steam_deck() {
  export SteamDeck=0
}
