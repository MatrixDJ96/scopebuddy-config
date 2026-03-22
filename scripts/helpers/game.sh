# The game: its executable, its config paths and the bundled assets.

resolve_game_executable() {
  local arg

  GAME_FILENAME=""
  GAME_DIRECTORY=""
  GAME_EXECUTABLE=""

  # The launcher quotes each word of ${command}: eval re-splits it, a path with spaces kept whole.
  eval "set -- ${command}"

  for arg in "$@"; do
    case "${arg,,}" in
      /*.exe)
        GAME_FILENAME="${arg##*/}"
        GAME_DIRECTORY="${arg%/*}"
        GAME_EXECUTABLE="${arg}"
        break
        ;;
    esac
  done

  scb_log "GAME_FILENAME: '$GAME_FILENAME'"
  scb_log "GAME_DIRECTORY: '$GAME_DIRECTORY'"
  scb_log "GAME_EXECUTABLE: '$GAME_EXECUTABLE'"
}

__resolve_game_context() {
  local provider
  local game_id

  __game_appid="${SCB_APPID}"

  if [[ ${SCB_APPID} == */* ]]; then
    game_id="${SCB_APPID#*/}"
    provider="${SCB_APPID%%/*}"
  else
    game_id="${SCB_APPID}"
    provider="steam"
  fi

  __game_env="${GAMES_PATH}/${provider}/${game_id}.env"
  __game_local_env="${GAMES_PATH}/${provider}/${game_id}.local.env"
  __game_config="${GAMES_PATH}/${provider}/${game_id}.conf"
  __game_local_config="${GAMES_PATH}/${provider}/${game_id}.local.conf"

  scb_log "__game_appid: '$__game_appid'"
  scb_log "__game_env: '$__game_env'"
  scb_log "__game_local_env: '$__game_local_env'"
  scb_log "__game_config: '$__game_config'"
  scb_log "__game_local_config: '$__game_local_config'"
}

replace_game_executable() {
  local new_game_executable="$1"

  if [[ -z ${__original_game_executable} ]]; then
    __original_game_executable="${GAME_EXECUTABLE}"
  fi

  command="${command/"${GAME_EXECUTABLE}"/"${new_game_executable}"}"
  GAME_EXECUTABLE="${new_game_executable}"
  scb_log "GAME_EXECUTABLE: '${new_game_executable}'"
}

restore_game_executable() {
  if [[ -z ${__original_game_executable} ]]; then
    return 1
  fi

  replace_game_executable "${__original_game_executable}"
}

# winetricks first: msiexec installs the legacy runtime on top.
install_physx_legacy() {
  execute_prefix_winetricks physx physx
  execute_prefix_wine physx_legacy \
    msiexec /i "${PHYSX_LEGACY_BINARY}" /qn
}
