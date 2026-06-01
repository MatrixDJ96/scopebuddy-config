# Asset helpers — wrap download_game_file (filesystem.sh) and bundled assets (paths.sh)

# Versioning constants for downloaded assets — bump to update
D3D8TO9_VERSION="1.15.1"

# Install the d3d8to9 native translation DLL into the target directory
# Combine with: export WINEDLLOVERRIDES="d3d8.dll=n,b"
# Argument: target directory (typically ${GAME_DIRECTORY})
install_d3d8to9() {
  download_game_file \
    "$1/d3d8.dll" \
    "https://github.com/crosire/d3d8to9/releases/download/v${D3D8TO9_VERSION}/d3d8.dll"
}

# Install NVIDIA PhysX legacy runtime into the current Wine prefix
# Sequence is mandatory: winetricks creates the base DLLs, msiexec installs
# the legacy SystemSoftware on top
install_physx_legacy() {
  execute_prefix_winetricks physx physx
  execute_prefix_wine physx_legacy \
    msiexec /i "${PHYSX_LEGACY_BINARY}" /qn
}

# Install the NoPSSDK v1.0.3 mod into the current game directory
# Used by Sony PC ports (e.g. God of War Ragnarök) that link against PSSDK at startup
install_nopssdk_v103() {
  install_game_files "${GAME_DIRECTORY}" "${NOPSSDK_PATH}"
}

# Generate rungame.bat next to a target exe and swap ${command} to launch via it
# Reads: GAME_EXECUTABLE, GAME_DIRECTORY, SCB_GAME_APPID
launch_via_rungame_bat() {
  local exe_name="$1"
  local extra_path="$2"
  local target_dir
  local bat_path

  if [[ -z ${exe_name} ]]; then
    [[ -z ${GAME_EXECUTABLE} ]] && return 1
    target_dir="${GAME_EXECUTABLE%/*}"
    exe_name="${GAME_EXECUTABLE##*/}"
  else
    if [[ -z ${extra_path} ]]; then
      target_dir="${GAME_DIRECTORY}"
    elif [[ ${extra_path} == /* ]]; then
      target_dir="${extra_path}"
    else
      target_dir="${GAME_DIRECTORY}/${extra_path}"
    fi
  fi

  bat_path="${target_dir}/rungame.bat"

  if [[ ! -f ${bat_path} ]]; then
    cat >"${bat_path}" <<EOF
set SteamAppId=${SCB_GAME_APPID}
set SteamGameId=${SCB_GAME_APPID}
"${exe_name}"
EOF
    scb_log_success "Created rungame.bat at ${bat_path}"
  fi

  replace_game_executable "${bat_path}"
}
