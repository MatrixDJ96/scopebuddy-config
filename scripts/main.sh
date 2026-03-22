# Loads the framework from SCB_CONFIGDIR and defines the launch phases.

source "${SCB_CONFIGDIR}/scripts/constants.sh"
source "${SCB_CONFIGDIR}/scripts/globals.sh"
source "${SCB_CONFIGDIR}/scripts/helpers/log.sh"

source "${SCB_CONFIGDIR}/scripts/helpers/launcher.sh"

source "${SCB_CONFIGDIR}/scripts/helpers/game.sh"

apply_profile_defaults() {
  local profile_name="$1"

  enable_auto_res
  enable_auto_vrr
  disable_auto_hdr

  case "${profile_name}" in
    scb)
      ;;
    noscope)
      ;;
    gamemode)
      ;;
    *)
      scb_log "Unknown profile: ${profile_name}"
      return 1
      ;;
  esac
}

# load_game_configs: unsets SCB_APPID so the launcher's own AppID/<id>.conf is not found.
load_game_configs() {
  __resolve_game_context

  source_if_exists "${__game_env}"
  source_if_exists "${__game_local_env}"
  source_if_exists "${__game_config}"
  source_if_exists "${__game_local_config}"

  unset SCB_APPID
}
