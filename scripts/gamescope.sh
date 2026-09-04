# Gamescope helpers and flag management

# Runtime state used to rebuild SCB_GAMESCOPE_ARGS
__gamescope_args=()

# Runtime framerate limit selected by the current profile or game config
SCB_FRAMERATE_LIMIT=""

# Rebuild SCB_GAMESCOPE_ARGS from the internal array
# If arguments are provided, replace the internal array first
__rebuild_gamescope_args() {
  if [[ $# -gt 0 ]]; then
    __gamescope_args=("$@")
  fi

  export SCB_GAMESCOPE_ARGS="${__gamescope_args[*]}"
  scb_log "SCB_GAMESCOPE_ARGS: '${SCB_GAMESCOPE_ARGS}'"
}

# Add one or more Gamescope arguments without duplicates
add_gamescope_flag() {
  local added_flag
  local existing_flag
  local gamescope_args

  gamescope_args=("${__gamescope_args[@]}")

  for added_flag in "$@"; do
    __trim_value added_flag "${added_flag}"

    [[ -z ${added_flag} ]] && continue

    for existing_flag in "${gamescope_args[@]}"; do
      if [[ ${existing_flag} == "${added_flag}" ]]; then
        continue 2
      fi
    done

    gamescope_args+=("${added_flag}")
  done

  __rebuild_gamescope_args "${gamescope_args[@]}"
}

# Remove one or more Gamescope arguments
remove_gamescope_flag() {
  local removed_flag
  local existing_flag
  local gamescope_args

  gamescope_args=()

  for existing_flag in "${__gamescope_args[@]}"; do
    for removed_flag in "$@"; do
      __trim_value removed_flag "${removed_flag}"

      [[ -z ${removed_flag} ]] && continue

      if [[ ${existing_flag} == "${removed_flag}" ]]; then
        continue 2
      fi
    done

    gamescope_args+=("${existing_flag}")
  done

  __rebuild_gamescope_args "${gamescope_args[@]}"
}

# Remove the current Gamescope framerate limit
__remove_gamescope_framerate_limit() {
  local existing_flag
  local gamescope_args

  gamescope_args=()

  for existing_flag in "${__gamescope_args[@]}"; do
    if [[ ${existing_flag} == -r\ * ]]; then
      continue
    fi

    gamescope_args+=("${existing_flag}")
  done

  __rebuild_gamescope_args "${gamescope_args[@]}"
}

# Apply the current framerate limit to Proton or Gamescope
__apply_framerate_limit() {
  local framerate="${SCB_FRAMERATE_LIMIT}"

  unset PROTON_FRAME_RATE
  __remove_gamescope_framerate_limit

  [[ -z ${framerate} ]] && return 0

  if [[ ${SCB_NOSCOPE} == "0" ]]; then
    add_gamescope_flag "-r ${framerate}"
  else
    export PROTON_FRAME_RATE="${framerate}"
  fi
}

# Enable Gamescope and move MangoHud inside Gamescope via mangoapp
enable_gamescope() {
  export MANGOHUD=0
  export SCB_NOSCOPE=0

  add_gamescope_flag "--mangoapp" "-f"
  __apply_framerate_limit
}

# Disable Gamescope and restore standalone MangoHud
disable_gamescope() {
  export MANGOHUD=1
  export SCB_NOSCOPE=1

  remove_gamescope_flag "--mangoapp" "-f"
  __apply_framerate_limit
}

# Set the framerate limit for the active rendering path
set_framerate_limit() {
  SCB_FRAMERATE_LIMIT="${1:-60}"
  __apply_framerate_limit

  scb_log_info "SCB_FRAMERATE_LIMIT: '${SCB_FRAMERATE_LIMIT}'"
  scb_log_info "PROTON_FRAME_RATE: '${PROTON_FRAME_RATE}'"
}
