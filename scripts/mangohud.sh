# MangoHud helpers

# Config layer paths: tracked base, optional local override, merged tmpfile
MANGOHUD_BASE_CONFIG=""
MANGOHUD_LOCAL_CONFIG=""
MANGOHUD_MERGED_CONFIG=""

# Presets layer paths: tracked base, optional local override, merged tmpfile
MANGOHUD_BASE_PRESETS=""
MANGOHUD_LOCAL_PRESETS=""
MANGOHUD_MERGED_PRESETS=""

# Build MANGOHUD_CONFIGFILE: base alone, or base + local merged into a tmpfile
prepare_mangohud_config() {
  MANGOHUD_BASE_CONFIG="${MANGOHUD_PATH}/MangoHud.conf"
  MANGOHUD_LOCAL_CONFIG="${MANGOHUD_PATH}/MangoHud.local.conf"
  MANGOHUD_MERGED_CONFIG=""

  if [[ -f ${MANGOHUD_LOCAL_CONFIG} ]]; then
    MANGOHUD_MERGED_CONFIG="$(mktemp --tmpdir "scopebuddy-mangohud.XXXXXX.conf")"

    cat "${MANGOHUD_BASE_CONFIG}" >"${MANGOHUD_MERGED_CONFIG}"
    printf '\n' >>"${MANGOHUD_MERGED_CONFIG}"
    cat "${MANGOHUD_LOCAL_CONFIG}" >>"${MANGOHUD_MERGED_CONFIG}"

    printf -v MANGOHUD_CONFIGFILE '%s' "${MANGOHUD_MERGED_CONFIG}"
  else
    printf -v MANGOHUD_CONFIGFILE '%s' "${MANGOHUD_BASE_CONFIG}"
  fi

  export MANGOHUD_CONFIGFILE
}

# Build MANGOHUD_PRESETSFILE: base alone, or base + local merged into a tmpfile
prepare_mangohud_presets() {
  MANGOHUD_BASE_PRESETS="${MANGOHUD_PATH}/presets.conf"
  MANGOHUD_LOCAL_PRESETS="${MANGOHUD_PATH}/presets.local.conf"
  MANGOHUD_MERGED_PRESETS=""

  if [[ -f ${MANGOHUD_LOCAL_PRESETS} ]]; then
    MANGOHUD_MERGED_PRESETS="$(mktemp --tmpdir "scopebuddy-mangohud-presets.XXXXXX.conf")"

    cat "${MANGOHUD_BASE_PRESETS}" >"${MANGOHUD_MERGED_PRESETS}"
    printf '\n' >>"${MANGOHUD_MERGED_PRESETS}"
    cat "${MANGOHUD_LOCAL_PRESETS}" >>"${MANGOHUD_MERGED_PRESETS}"

    printf -v MANGOHUD_PRESETSFILE '%s' "${MANGOHUD_MERGED_PRESETS}"
  else
    printf -v MANGOHUD_PRESETSFILE '%s' "${MANGOHUD_BASE_PRESETS}"
  fi

  export MANGOHUD_PRESETSFILE
}

# Resolve both the MangoHud config and presets files
set_mangohud_config() {
  prepare_mangohud_config
  prepare_mangohud_presets
}
