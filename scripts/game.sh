# Game helpers
# These values are derived from the current launch context so game-specific
# configs can inspect the executable and the config lookup key in one place

# Runtime values populated from the current launch command
GAME_FILENAME=""
GAME_DIRECTORY=""
GAME_EXECUTABLE=""

# Runtime values populated while resolving the current game config
SCB_GAME_APPID=""
SCB_GAME_CONFIG=""
SCB_GAME_LOCAL_CONFIG=""

# Private module state: original GAME_EXECUTABLE captured by replace_game_executable
__original_game_executable=""

# Resolve the current game executable from the launch command
resolve_game_executable() {
  local arg

  GAME_FILENAME=""
  GAME_DIRECTORY=""
  GAME_EXECUTABLE=""

  # shellcheck disable=SC2154 # `command` is set by the launcher before sourcing this file
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

# Resolve the current game provider and identifier from SCB_APPID
# A numeric id means Steam; any <provider>/<id> value maps to games/<provider>/<id>.conf
resolve_game_context() {
  local appid="${SCB_APPID:-}"
  local provider=""
  local game_id=""

  SCB_GAME_APPID="${appid}"
  SCB_GAME_CONFIG=""
  SCB_GAME_LOCAL_CONFIG=""

  if [[ -z ${appid} ]]; then
    return 0
  fi

  if [[ ${appid} == */* ]]; then
    game_id="${appid#*/}"
    provider="${appid%%/*}"
  else
    game_id="${appid}"
    provider="steam"
  fi

  SCB_GAME_CONFIG="${GAMES_PATH}/${provider}/${game_id}.conf"
  SCB_GAME_LOCAL_CONFIG="${GAMES_PATH}/${provider}/${game_id}.local.conf"

  scb_log "SCB_GAME_APPID: '$SCB_GAME_APPID'"
  scb_log "SCB_GAME_CONFIG: '$SCB_GAME_CONFIG'"
  scb_log "SCB_GAME_LOCAL_CONFIG: '$SCB_GAME_LOCAL_CONFIG'"
}

# Substitute the previous GAME_EXECUTABLE for $1 in ${command}; capture original on first call
replace_game_executable() {
  local old_game_executable=""
  local new_game_executable="$1"

  [[ -z ${GAME_EXECUTABLE} ]] && return 1

  if [[ -z ${__original_game_executable} ]]; then
    __original_game_executable="${GAME_EXECUTABLE}"
  fi

  old_game_executable="${GAME_EXECUTABLE}"
  GAME_EXECUTABLE="${new_game_executable}"
  scb_log "GAME_EXECUTABLE: '${new_game_executable}'"

  # shellcheck disable=SC2154
  command="${command/${old_game_executable}/${new_game_executable}}"
}

# Revert to the original GAME_EXECUTABLE captured by replace_game_executable
restore_game_executable() {
  [[ -z ${__original_game_executable} ]] && return 1

  replace_game_executable "${__original_game_executable}"
}
