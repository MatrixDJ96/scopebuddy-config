# Values from the launch environment and the launch state the helpers fill.

WINDOWS_USER="${WINDOWS_USER:-MatrixDJ96}"
USER_DATA_PATH="${HOME}/.local/share"
WINDOWS_USER_PATH="/run/media/${USER}/Windows/Users/${WINDOWS_USER}"
WINDOWS_ROAMING_PATH="${WINDOWS_USER_PATH}/AppData/Roaming"

COMPAT_TOOL_PATH="${STEAM_COMPAT_TOOL_PATHS%%:*}"
COMPAT_TOOL_PATH="${COMPAT_TOOL_PATH:-${PROTONPATH}}"
COMPAT_WINE_BINARY="${COMPAT_TOOL_PATH}/files/bin/wine"
COMPAT_WINETRICKS_BINARY="${COMPAT_TOOL_PATH}/protonfixes/winetricks"

WINEPREFIX="${WINEPREFIX:-${STEAM_COMPAT_DATA_PATH:+${STEAM_COMPAT_DATA_PATH}/pfx}}"
PREFIX_USER_PATH="${WINEPREFIX}/drive_c/users/steamuser"
PREFIX_ROAMING_PATH="${PREFIX_USER_PATH}/AppData/Roaming"

GAME_FILENAME=""
GAME_DIRECTORY=""
GAME_EXECUTABLE=""
SCB_GAME_NATIVE=""

__game_appid=""
__game_env=""
__game_local_env=""
__game_config=""
__game_local_config=""

__original_game_executable=""

__gamescope_args=()
__framerate_limit=""
__proton_wayland_suspended=""
__proton_steaminput_suspended=""
