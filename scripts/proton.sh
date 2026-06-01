# Proton feature helpers

# Export a CachyOS-only env var; warn and return 1 on other Proton variants
_require_proton_cachyos() {
  local var_name="$1"
  local value="$2"

  if [[ ${COMPAT_TOOL_PATH,,} == *cachyos* ]]; then
    export "${var_name}=${value}"
    return 0
  fi

  scb_log_warning "${var_name} requires Proton-CachyOS"
  return 1
}

# Add a token to the comma-separated VKD3D_CONFIG list (idempotent)
_vkd3d_config_add() {
  local token="$1"

  case ",${VKD3D_CONFIG:-}," in
    *",${token},"*) ;;
    *) export VKD3D_CONFIG="${VKD3D_CONFIG:+${VKD3D_CONFIG},}${token}" ;;
  esac
}

# Remove a token from the comma-separated VKD3D_CONFIG list
_vkd3d_config_remove() {
  local token="$1"
  local out="" field
  local IFS=','

  # shellcheck disable=SC2086 # intentional word-split on commas
  for field in ${VKD3D_CONFIG:-}; do
    [[ ${field} == "${token}" ]] && continue
    out="${out:+${out},}${field}"
  done

  if [[ -n ${out} ]]; then
    export VKD3D_CONFIG="${out}"
  else
    unset VKD3D_CONFIG
  fi
}

# Enable Proton WOW64
enable_proton_wow64() {
  export PROTON_USE_WOW64=1
}

# Disable Proton WOW64
disable_proton_wow64() {
  export PROTON_USE_WOW64=0
}

# Enable Proton NTSYNC and disable ESYNC/FSYNC
enable_proton_ntsync() {
  export PROTON_NO_ESYNC=1
  export PROTON_NO_FSYNC=1
}

# Disable Proton NTSYNC and restore ESYNC/FSYNC
disable_proton_ntsync() {
  export PROTON_NO_ESYNC=0
  export PROTON_NO_FSYNC=0
}

# Enable Proton Wayland
enable_proton_wayland() {
  export PROTON_ENABLE_WAYLAND=1
}

# Disable Proton Wayland
disable_proton_wayland() {
  export PROTON_ENABLE_WAYLAND=0
}

# Load the dxvk-nvapi-vkreflex layer
enable_proton_vkreflex() {
  export DXVK_NVAPI_VKREFLEX=1
}

# Disable Proton VKReflex
disable_proton_vkreflex() {
  export DXVK_NVAPI_VKREFLEX=0
}

# Enable Proton DXVK low-latency mode (CachyOS-only)
enable_proton_dxvk_lowlatency() {
  _require_proton_cachyos "PROTON_DXVK_LOWLATENCY" 1
}

# Disable Proton DXVK low-latency mode (CachyOS-only)
disable_proton_dxvk_lowlatency() {
  _require_proton_cachyos "PROTON_DXVK_LOWLATENCY" 0
}

# Select the native vkd3d descriptor-heap path (VK_EXT_descriptor_heap)
enable_proton_vkd3d_heap() {
  _vkd3d_config_add descriptor_heap
}

# Return to the default vkd3d descriptor path
disable_proton_vkd3d_heap() {
  _vkd3d_config_remove descriptor_heap
}

# Enable Intel XeSS upgrade
enable_proton_xess() {
  export PROTON_XESS_UPGRADE=1
}

# Disable Intel XeSS upgrade
disable_proton_xess() {
  export PROTON_XESS_UPGRADE=0
}

# Enable Proton DXVK d3d8 translation (d3d8 -> d3d11 -> Vulkan)
enable_proton_dxvk_d3d8() {
  export PROTON_DXVK_D3D8=1
}

# Disable Proton DXVK d3d8 translation
disable_proton_dxvk_d3d8() {
  export PROTON_DXVK_D3D8=0
}

# Enable HDR output (DXVK_HDR, read by dxgi.dll on CachyOS and GE)
enable_proton_hdr() {
  export DXVK_HDR=1
  export DXVK_NO_HDR=0
}

# Disable HDR output (explicit off via DXVK_NO_HDR)
disable_proton_hdr() {
  export DXVK_HDR=0
  export DXVK_NO_HDR=1
}
