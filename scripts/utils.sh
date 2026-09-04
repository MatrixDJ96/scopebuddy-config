# Generic helpers shared by all modules

SCB_PREFIX_COLOR="\033[35m"
SCB_SUCCESS_COLOR="\033[32m"
SCB_WARNING_COLOR="\033[33m"
SCB_ERROR_COLOR="\033[31m"
SCB_INFO_COLOR="\033[36m"
SCB_RESET_COLOR="\033[0m"

# Print a ScopeBuddy log message with a stable prefix
scb_log() {
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} %s\n" "$*"
}

# Print a success log message
scb_log_success() {
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} ${SCB_SUCCESS_COLOR}%s${SCB_RESET_COLOR}\n" "$*"
}

# Print an info log message
scb_log_info() {
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} ${SCB_INFO_COLOR}%s${SCB_RESET_COLOR}\n" "$*"
}

# Print a warning log message
scb_log_warning() {
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} ${SCB_WARNING_COLOR}%s${SCB_RESET_COLOR}\n" "$*"
}

# Print an error log message
scb_log_error() {
  printf "${SCB_PREFIX_COLOR}[SCB]${SCB_RESET_COLOR} ${SCB_ERROR_COLOR}%s${SCB_RESET_COLOR}\n" "$*"
}

# Remove leading and trailing spaces from a string
__trim_value() {
  local name="$1"
  local value="$2"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf -v "${name}" '%s' "${value}"
}

# Source a file only if it exists
# A missing optional layer is a no-op, so a game launch survives an absent profile.local or game.local
source_if_exists() {
  local file="$1"

  if [[ -f ${file} ]]; then
    # shellcheck disable=SC1090 # dynamic source path: per-game and per-profile overrides
    source "${file}"
  fi

  return 0
}
