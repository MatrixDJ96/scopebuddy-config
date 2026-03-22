# Values from the launch environment and the launch state the helpers fill.

COMPAT_TOOL_PATH="${STEAM_COMPAT_TOOL_PATHS%%:*}"
COMPAT_TOOL_PATH="${COMPAT_TOOL_PATH:-${PROTONPATH}}"
COMPAT_WINE_BINARY="${COMPAT_TOOL_PATH}/files/bin/wine"
COMPAT_WINETRICKS_BINARY="${COMPAT_TOOL_PATH}/protonfixes/winetricks"

WINEPREFIX="${WINEPREFIX:-${STEAM_COMPAT_DATA_PATH:+${STEAM_COMPAT_DATA_PATH}/pfx}}"

GAME_FILENAME=""
GAME_DIRECTORY=""
GAME_EXECUTABLE=""

__game_appid=""
__game_env=""
__game_local_env=""
__game_config=""
__game_local_config=""

__original_game_executable=""

__gamescope_args=()
__framerate_limit=""
__proton_wayland_suspended=""
