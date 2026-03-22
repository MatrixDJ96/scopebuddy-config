# Commands and registry writes inside WINEPREFIX, run with the active Proton's wine on PATH.

execute_prefix_command() {
  scb_log_warning "Executing command: '$*'..."
  PATH="$(dirname "${COMPAT_WINE_BINARY}"):${PATH}" WINEPREFIX="${WINEPREFIX}" "$@"
}

# execute_prefix_command_once <name> <command>...
execute_prefix_command_once() {
  local name="$1"
  shift
  local flag="${WINEPREFIX}/.${name}"

  if [[ -f ${flag} ]]; then
    return 0
  fi

  if execute_prefix_command "$@"; then
    touch "${flag}"
    return 0
  fi

  scb_log_error "Failed to execute command"
  return 1
}

# __strip_batch_pause <script> <copy>: cmd /c would wait on a pause.
__strip_batch_pause() {
  sed '/^[[:space:]]*pause[[:space:]]*$/Id' "$1" >"$2"
}

# execute_prefix_wine <name> <program> [<argument>...]
execute_prefix_wine() {
  local name="$1"
  shift
  local program="$1"
  shift
  local temp_script

  if [[ -z ${program} ]]; then
    return 1
  fi

  if [[ ${program,,} == *.bat || ${program,,} == *.cmd ]]; then
    temp_script="/tmp/${name}.bat"
    __strip_batch_pause "${program}" "${temp_script}"
    execute_prefix_command_once "${name}" "${COMPAT_WINE_BINARY}" cmd /c "${temp_script}" "$@"
  else
    execute_prefix_command_once "${name}" "${COMPAT_WINE_BINARY}" "${program}" "$@"
  fi
}

execute_prefix_winetricks() {
  local name="$1"
  shift
  execute_prefix_command_once "${name}" "${COMPAT_WINETRICKS_BINARY}" -q --force "$@"
}

# set_prefix_dpi_value [<dpi>]: rewritten on every call.
set_prefix_dpi_value() {
  local dpi="${1:-96}"

  execute_prefix_command \
    "${COMPAT_WINE_BINARY}" reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' \
    /v LogPixels /t REG_DWORD /d "${dpi}" /f
}

# set_prefix_dpi_scale <percent|factor>: 150 or 1.5; a factor needs its dot (2.0).
set_prefix_dpi_scale() {
  local scale="${1:-100}"
  local percent
  local dpi

  if [[ ${scale} == *.* ]]; then
    percent="$(awk -v scale="${scale}" 'BEGIN { printf "%.0f", scale * 100 }')"
  else
    percent="${scale}"
  fi

  dpi=$((96 * percent / 100))
  set_prefix_dpi_value "${dpi}"
}

# set_prefix_registry_value <key> <name> <type> <data>: only when the value is absent.
set_prefix_registry_value() {
  local reg_key="$1"
  local value_name="$2"
  local value_type="$3"
  local value_data="$4"

  if execute_prefix_command "${COMPAT_WINE_BINARY}" reg query "${reg_key}" \
    /v "${value_name}" >/dev/null 2>&1; then
    return 0
  fi

  execute_prefix_command "${COMPAT_WINE_BINARY}" reg add "${reg_key}" \
    /v "${value_name}" /t "${value_type}" /d "${value_data}" /f
}

# set_prefix_registry_values <key> <name|type|data>...
set_prefix_registry_values() {
  local reg_key="$1"
  shift
  local entry
  local value_name
  local value_type
  local value_data

  for entry in "$@"; do
    IFS='|' read -r value_name value_type value_data <<<"${entry}"
    set_prefix_registry_value "${reg_key}" "${value_name}" "${value_type}" "${value_data}"
  done
}
