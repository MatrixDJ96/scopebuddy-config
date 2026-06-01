# GPU and image quality helpers

# Expose the NVIDIA GPU to Proton and DXVK
enable_nvidia_gpu() {
  export PROTON_FORCE_NVAPI=1
  export PROTON_HIDE_NVIDIA_GPU=0
}

# Hide the NVIDIA GPU from Proton and DXVK
disable_nvidia_gpu() {
  export PROTON_FORCE_NVAPI=0
  export PROTON_HIDE_NVIDIA_GPU=1
}

# Hide the Intel iGPU from Proton/DXVK (laptop dual-GPU systems)
disable_intel_gpu() {
  export PROTON_HIDE_INTEL_GPU=1
}

# Expose the Intel iGPU to Proton/DXVK
enable_intel_gpu() {
  unset PROTON_HIDE_INTEL_GPU
}

# Enable NVIDIA Smooth Motion
enable_smooth_motion() {
  export NVPRESENT_LOG_LEVEL=4
  export NVPRESENT_ENABLE_SMOOTH_MOTION=1
}

# Disable NVIDIA Smooth Motion
disable_smooth_motion() {
  export NVPRESENT_LOG_LEVEL=4
  export NVPRESENT_ENABLE_SMOOTH_MOTION=0
}

# Enable the DLSS and frame generation debug indicators
enable_dlss_indicator() {
  export PROTON_DLSS_INDICATOR=1
  export DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS="DLSSIndicator=1024,DLSSGIndicator=2,"
}

# Override the DLSS version and optionally force SR/RR presets
enable_dlss_override() {
  local a="${1:-}"
  local b="${2:-}"
  local c="${3:-}"

  local version="0"
  local sr_preset=""
  local rr_preset=""

  if [[ $a =~ ^[A-Za-z]$ ]]; then
    sr_preset="render_preset_${a,,}"

    if [[ $b =~ ^[A-Za-z]$ ]]; then
      rr_preset="render_preset_${b,,}"
    else
      rr_preset="render_preset_latest"
    fi
  else
    version="${a:-latest}"

    if [[ $b =~ ^[A-Za-z]$ ]]; then
      sr_preset="render_preset_${b,,}"

      if [[ $c =~ ^[A-Za-z]$ ]]; then
        rr_preset="render_preset_${c,,}"
      else
        rr_preset="render_preset_latest"
      fi
    fi
  fi

  if [[ ${version,,} == "latest" ]]; then
    version="1"
  fi

  export PROTON_DLSS_UPGRADE="${version}"

  if [[ -n ${sr_preset} ]]; then
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION="${sr_preset}"
  fi

  if [[ -n ${rr_preset} ]]; then
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION="${rr_preset}"
  fi

  scb_log "DLSS: PROTON_DLSS_UPGRADE=${version} SR=${sr_preset:-<unchanged>} RR=${rr_preset:-<unchanged>}"
}
