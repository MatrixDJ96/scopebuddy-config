# Config loading helpers

# Runtime values populated while selecting the active profile config files
SCB_PROFILE_NAME=""
SCB_PROFILE_LOCAL_CONFIG=""

# Build the optional local config file associated with a top-level profile
resolve_profile_local_config() {
  local profile_name="$1"

  SCB_PROFILE_NAME="${profile_name}"
  SCB_PROFILE_LOCAL_CONFIG=""

  if [[ -z ${profile_name} ]]; then
    return 0
  fi

  SCB_PROFILE_LOCAL_CONFIG="${SCOPEBUDDY_PATH}/${profile_name}.local.conf"
}

# Apply the selected profile defaults and then load its optional local layer
load_profile_configs() {
  local profile_name="$1"

  resolve_profile_local_config "${profile_name}"
  apply_profile_defaults "${profile_name}"
  source_if_exists "${SCB_PROFILE_LOCAL_CONFIG}"
}

# Load the shared game config first and the local game config after it
# Warning: SCB_APPID is unset at the end so the launcher's own loader skips the old AppID path
load_game_configs() {
  resolve_game_context

  if [[ -z ${SCB_GAME_APPID} ]]; then
    return 0
  fi

  source_if_exists "${SCB_GAME_CONFIG}"
  source_if_exists "${SCB_GAME_LOCAL_CONFIG}"

  unset SCB_APPID
}
