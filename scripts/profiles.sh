# Profile defaults used by the top-level ScopeBuddy entrypoints

# Apply the baseline toggle set shared by every profile
apply_default_config() {
  # Disable Deck mode
  disable_steam_deck

  # Disable Gamescope
  disable_gamescope

  # Set MangoHud config
  set_mangohud_config

  # Enable auto settings
  enable_auto_res
  enable_auto_vrr
  disable_auto_hdr

  # Enable Proton WOW64
  enable_proton_wow64

  # Enable Proton NTSYNC
  enable_proton_ntsync

  # Enable Nvidia (nvapi)
  enable_nvidia_gpu

  # Enable Wayland support
  # enable_proton_wayland
}

# Apply the defaults for the selected top-level profile
apply_profile_defaults() {
  local profile_name="$1"

  case "${profile_name}" in
    scb | noscope | gamemode)
      apply_default_config
      ;;
    *)
      scb_log "Unknown profile: ${profile_name}"
      return 1
      ;;
  esac
}
