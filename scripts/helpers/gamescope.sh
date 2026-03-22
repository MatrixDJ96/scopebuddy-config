# Gamescope mode and flags, the framerate limit and the MangoHud config files.

__set_gamescope_args() {
  __gamescope_args=("$@")

  export SCB_GAMESCOPE_ARGS="${__gamescope_args[*]}"
  scb_log "SCB_GAMESCOPE_ARGS: '${SCB_GAMESCOPE_ARGS}'"
}

# __trim_value <name> <value>: the value without leading and trailing blanks, into <name>.
__trim_value() {
  local name="$1"
  local value="$2"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf -v "${name}" '%s' "${value}"
}

# add_gamescope_flag <flag>...: a flag with its value is one argument ("-w 1920").
add_gamescope_flag() {
  local added_flag
  local existing_flag
  local gamescope_args

  gamescope_args=("${__gamescope_args[@]}")

  for added_flag in "$@"; do
    __trim_value added_flag "${added_flag}"

    if [[ -z ${added_flag} ]]; then
      continue
    fi

    for existing_flag in "${gamescope_args[@]}"; do
      if [[ ${existing_flag} == "${added_flag}" ]]; then
        continue 2
      fi
    done

    gamescope_args+=("${added_flag}")
  done

  __set_gamescope_args "${gamescope_args[@]}"
}

# remove_gamescope_flag <flag>...: each matched whole.
remove_gamescope_flag() {
  local removed_flag
  local existing_flag
  local gamescope_args

  gamescope_args=()

  for existing_flag in "${__gamescope_args[@]}"; do
    for removed_flag in "$@"; do
      __trim_value removed_flag "${removed_flag}"

      if [[ ${existing_flag} == "${removed_flag}" ]]; then
        continue 2
      fi
    done

    gamescope_args+=("${existing_flag}")
  done

  __set_gamescope_args "${gamescope_args[@]}"
}

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

  __set_gamescope_args "${gamescope_args[@]}"
}

__apply_framerate_limit() {
  unset PROTON_FRAME_RATE
  __remove_gamescope_framerate_limit

  if [[ -z ${__framerate_limit} ]]; then
    return 0
  fi

  if [[ ${SCB_NOSCOPE} == "0" ]]; then
    add_gamescope_flag "-r ${__framerate_limit}"
  else
    export PROTON_FRAME_RATE="${__framerate_limit}"
  fi
}

# 0 when KDE reports HDR on its primary output: the enabled one with the lowest priority number.
__display_hdr_enabled() {
  local kscreen=${KSCREEN_COMMAND:-kscreen-doctor}
  local primary='(.outputs | map(select(.enabled)) | sort_by(.priority))[0].hdr'
  local outputs
  local hdr=0

  if ! command -v "${kscreen}" >/dev/null; then
    scb_log_warning "HDR not detected: ${kscreen} not found"
    return 1
  fi

  if ! outputs=$("${kscreen}" -j 2>/dev/null); then
    scb_log_warning "HDR not detected: ${kscreen} -j failed"
    return 1
  fi

  if [[ $(jq -r "${primary}" <<<"${outputs}" 2>/dev/null || true) == "true" ]]; then
    hdr=1
  fi

  scb_log "Display HDR: ${hdr}"
  [[ ${hdr} == "1" ]]
}

# 0 when gamescope can start: installed, and not in Game Mode, where a nested one fails.
__gamescope_available() {
  if [[ ${SCB_GAMEMODE:-0} == "1" ]]; then
    scb_log_warning "Gamescope stays off in Game Mode"
    return 1
  fi

  if ! command -v "${GAMESCOPE_BIN:-gamescope}" >/dev/null; then
    scb_log_warning "Gamescope stays off: ${GAMESCOPE_BIN:-gamescope} not found"
    return 1
  fi
}

# MangoHud, the gamescope flags and the framerate limit for SCB_NOSCOPE.
__apply_gamescope_mode() {
  if [[ ${SCB_NOSCOPE} == "0" ]]; then
    export MANGOHUD=0
    add_gamescope_flag "--mangoapp" "-f"

    if __display_hdr_enabled; then
      add_gamescope_flag "--hdr-enabled"
    fi
  else
    export MANGOHUD=1
    remove_gamescope_flag "--mangoapp" "-f" "--hdr-enabled"
  fi

  __apply_framerate_limit
}

enable_gamescope() {
  if ! __gamescope_available; then
    disable_gamescope
    return 0
  fi

  export SCB_NOSCOPE=0
  __apply_gamescope_mode
}

disable_gamescope() {
  export SCB_NOSCOPE=1
  __apply_gamescope_mode
}

# set_framerate_limit [<fps>]
set_framerate_limit() {
  __framerate_limit="${1:-60}"
  __apply_framerate_limit

  scb_log_info "Framerate limit: '${__framerate_limit}'"
  scb_log_info "PROTON_FRAME_RATE: '${PROTON_FRAME_RATE}'"
}

# __merge_mangohud_layer <base> <local> <tmpfile pattern>: prints the merged file, else <base>.
__merge_mangohud_layer() {
  local base="$1"
  local local_layer="$2"
  local merged

  if [[ ! -f ${local_layer} ]]; then
    printf '%s' "${base}"
    return 0
  fi

  if merged="$(mktemp --tmpdir "$3")" \
    && cat "${base}" >"${merged}" \
    && printf '\n' >>"${merged}" \
    && cat "${local_layer}" >>"${merged}"; then
    printf '%s' "${merged}"
    return 0
  fi

  rm -f "${merged}"
  scb_log_error "Failed to merge ${local_layer}; ${base} applies alone" >&2
  printf '%s' "${base}"
}

__prepare_mangohud_config() {
  MANGOHUD_CONFIGFILE="$(__merge_mangohud_layer "${MANGOHUD_PATH}/MangoHud.conf" \
    "${MANGOHUD_PATH}/MangoHud.local.conf" "scopebuddy-mangohud.XXXXXX.conf")"
  export MANGOHUD_CONFIGFILE
}

__prepare_mangohud_presets() {
  MANGOHUD_PRESETSFILE="$(__merge_mangohud_layer "${MANGOHUD_PATH}/presets.conf" \
    "${MANGOHUD_PATH}/presets.local.conf" "scopebuddy-mangohud-presets.XXXXXX.conf")"
  export MANGOHUD_PRESETSFILE
}

set_mangohud_config() {
  __prepare_mangohud_config
  __prepare_mangohud_presets
}
