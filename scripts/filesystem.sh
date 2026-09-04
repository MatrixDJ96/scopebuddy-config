# Filesystem helpers used by game-specific configs

# Replace a target directory with a symlink to a source directory
# Destructive: rm -rf on the target every call when the source exists
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

# Copy one or more files or directories into a target directory
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

# Download a file to a target path using one or more candidate URLs
download_game_file() {
  local target_file="$1"
  shift
  local download_url

  [[ -f ${target_file} ]] && return 0

  mkdir -p "$(dirname "${target_file}")"

  for download_url in "$@"; do
    scb_log_warning "Downloading ${target_file} from ${download_url}..."
    if env -u LD_PRELOAD -u LD_LIBRARY_PATH PATH="/usr/bin:/bin" \
      /usr/bin/curl -L --fail --output "${target_file}" "${download_url}"; then
      scb_log_success "File ${target_file} downloaded successfully!"
      return 0
    fi
  done

  scb_log_error "Failed to download ${target_file}"
  return 1
}
