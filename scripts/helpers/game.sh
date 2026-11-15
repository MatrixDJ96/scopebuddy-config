# The game: its executable, its config paths, the files in its directory and the bundled assets.

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

# symlink_directory <source> <target>
symlink_directory() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d ${source_dir} ]]; then
    scb_log_warning "Skipping symlink, source not found: ${source_dir}"
    return 0
  fi

  mkdir -p "$(dirname "${target_dir}")"
  rm -rf "${target_dir}"
  ln -s "${source_dir}" "${target_dir}"
}

# install_game_files <target> <path>...
install_game_files() {
  local target_dir="$1"
  shift
  local source_path

  mkdir -p "${target_dir}"

  for source_path in "$@"; do
    if [[ -d ${source_path} ]]; then
      cp -rf "${source_path}/." "${target_dir}/"
    elif [[ -f ${source_path} ]]; then
      cp -f "${source_path}" "${target_dir}/"
    fi
  done
}

# download_game_file <file> <url>...: status 0 when every URL fails; the next launch retries.
download_game_file() {
  local target_file="$1"
  shift
  local download_url

  if [[ -f ${target_file} ]]; then
    return 0
  fi

  mkdir -p "$(dirname "${target_file}")"

  for download_url in "$@"; do
    scb_log_warning "Downloading ${target_file} from ${download_url}..."
    if env -u LD_PRELOAD -u LD_LIBRARY_PATH PATH="/usr/bin:/bin" \
      /usr/bin/curl -L --fail --remove-on-error --output "${target_file}" "${download_url}"; then
      scb_log_success "File ${target_file} downloaded successfully!"
      return 0
    fi
  done

  scb_log_error "Failed to download ${target_file}; the launch goes on without it"
}

# install_d3d8to9 <directory>
install_d3d8to9() {
  download_game_file \
    "$1/d3d8.dll" \
    "https://github.com/crosire/d3d8to9/releases/download/v${D3D8TO9_VERSION}/d3d8.dll"
}

# winetricks first: msiexec installs the legacy runtime on top.
install_physx_legacy() {
  execute_prefix_winetricks physx physx
  execute_prefix_wine physx_legacy \
    msiexec /i "${PHYSX_LEGACY_BINARY}" /qn
}

install_pspcsdk_emulator_v11() {
  install_game_files "${GAME_DIRECTORY}" "${PSPCSDK_EMULATOR_PATH}"
}

__rungame_bat_dir() {
  if [[ -z $1 ]]; then
    printf '%s' "${GAME_DIRECTORY}"
  elif [[ $1 == /* ]]; then
    printf '%s' "$1"
  else
    printf '%s' "${GAME_DIRECTORY}/$1"
  fi
}

# __write_rungame_bat <bat> <exe>: kept once written.
__write_rungame_bat() {
  if [[ -f $1 ]]; then
    return 0
  fi

  cat >"$1" <<EOF
set SteamAppId=${__game_appid}
set SteamGameId=${__game_appid}
"$2"
EOF
  scb_log_success "Created rungame.bat at $1"
}

# launch_via_rungame_bat [<exe> [<directory>]]
launch_via_rungame_bat() {
  local exe_name="$1"
  local extra_path="$2"
  local target_dir
  local bat_path

  if [[ -z ${exe_name} ]]; then
    target_dir="${GAME_EXECUTABLE%/*}"
    exe_name="${GAME_EXECUTABLE##*/}"
  else
    target_dir="$(__rungame_bat_dir "${extra_path}")"
  fi

  bat_path="${target_dir}/rungame.bat"
  __write_rungame_bat "${bat_path}" "${exe_name}"
  replace_game_executable "${bat_path}"
}
