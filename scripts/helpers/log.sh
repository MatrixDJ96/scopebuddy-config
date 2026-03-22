# Logging and optional sourcing.

scb_log() {
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} %s\n" "$*"
}

__scb_log_in_color() {
  local color=$1

  shift
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} ${color}%s${SCB_RESET_COLOR}\n" "$*"
}

scb_log_success() {
  __scb_log_in_color "${SCB_SUCCESS_COLOR}" "$@"
}

scb_log_info() {
  __scb_log_in_color "${SCB_INFO_COLOR}" "$@"
}

scb_log_warning() {
  __scb_log_in_color "${SCB_WARNING_COLOR}" "$@"
}

scb_log_error() {
  __scb_log_in_color "${SCB_ERROR_COLOR}" "$@"
}

# source_if_exists <file>: always status 0; a failing file still aborts a shell under errexit.
source_if_exists() {
  local file="$1"

  if [[ -f ${file} ]]; then
    # shellcheck disable=SC1090 # dynamic source path: per-game and per-profile overrides
    source "${file}"
  fi

  return 0
}
