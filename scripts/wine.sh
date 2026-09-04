# Wine helpers used to run commands inside the current Wine prefix

# Execute a command inside the current Wine prefix
execute_prefix_command() {
  local path
  local prefix="${WINEPREFIX}"

  path="$(dirname "${COMPAT_WINE_BINARY}"):${PATH}"

  [[ -z ${prefix} ]] && return 1

  scb_log_warning "Executing command: '$*'..."
  PATH="${path}" WINEPREFIX="${prefix}" "$@"
}

# Execute a command once inside the current Wine prefix
execute_prefix_command_once() {
  local name="$1"
  shift
  local prefix="${WINEPREFIX}"
  local flag="${prefix}/.${name}"

  [[ -z ${prefix} ]] && return 1
  [[ -f ${flag} ]] && return 0

  if execute_prefix_command "$@"; then
    touch "${flag}"
    return 0
  fi

  scb_log_error "Failed to execute command"
  return 1
}

# Execute a Wine command once inside the current Wine prefix
# If the first argument is a .bat or .cmd file, remove pause lines and run it through cmd
execute_prefix_wine() {
  local name="$1"
  shift
  local program="$1"
  shift
  local temp_script=""

  [[ -z ${program} ]] && return 1

  if [[ ${program,,} == *.bat || ${program,,} == *.cmd ]]; then
    temp_script="/tmp/${name}.bat"
    sed '/^[[:space:]]*pause[[:space:]]*$/Id' "${program}" >"${temp_script}"
    execute_prefix_command_once "${name}" "${COMPAT_WINE_BINARY}" cmd /c "${temp_script}" "$@"
  else
    execute_prefix_command_once "${name}" "${COMPAT_WINE_BINARY}" "${program}" "$@"
  fi
}

# Execute winetricks once inside the current Wine prefix
execute_prefix_winetricks() {
  local name="$1"
  shift
  execute_prefix_command_once "${name}" "${COMPAT_WINETRICKS_BINARY}" -q --force "$@"
}

# Set a raw DPI value for the current Wine prefix
set_prefix_dpi_value() {
  local dpi="${1:-96}"

  execute_prefix_command \
    "${COMPAT_WINE_BINARY}" reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' \
    /v LogPixels /t REG_DWORD /d "${dpi}" /f
}

# Set DPI scaling for the current Wine prefix
# Accepts either a percentage (150) or a factor (1.5)
set_prefix_dpi_scale() {
  local scale="${1:-100}"
  local percent=""
  local dpi=""

  if [[ ${scale} == *.* ]]; then
    percent="$(awk -v scale="${scale}" 'BEGIN { printf "%.0f", scale * 100 }')"
  else
    percent="${scale}"
  fi

  dpi=$((96 * percent / 100))
  set_prefix_dpi_value "${dpi}"
}

# Set a single registry value in the current Wine prefix
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

# Set multiple registry values in the current Wine prefix
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
