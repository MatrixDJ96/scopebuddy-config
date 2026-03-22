# Values from the launch environment and the launch state the helpers fill.

COMPAT_TOOL_PATH="${STEAM_COMPAT_TOOL_PATHS%%:*}"
COMPAT_TOOL_PATH="${COMPAT_TOOL_PATH:-${PROTONPATH}}"

GAME_FILENAME=""
GAME_DIRECTORY=""
GAME_EXECUTABLE=""

__game_appid=""
__game_env=""
__game_local_env=""
__game_config=""
__game_local_config=""

__original_game_executable=""
