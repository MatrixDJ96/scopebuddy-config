# Shared paths used by all ScopeBuddy profiles

# User paths
WINDOWS_USER="${WINDOWS_USER:-MatrixDJ96}"
USER_CONFIG_PATH="${HOME}/.config"
USER_DATA_PATH="${HOME}/.local/share"
WINDOWS_USER_PATH="/run/media/${USER}/Windows/Users/${WINDOWS_USER}"
WINDOWS_ROAMING_PATH="${WINDOWS_USER_PATH}/AppData/Roaming"

# ScopeBuddy repository paths
SCOPEBUDDY_PATH="${SCB_CONFIGDIR:-${USER_CONFIG_PATH}/scopebuddy}"
MANGOHUD_PATH="${SCOPEBUDDY_PATH}/mangohud"
ASSETS_PATH="${SCOPEBUDDY_PATH}/assets"
GAMES_PATH="${SCOPEBUDDY_PATH}/games"

# Asset paths used by helper functions
NOPSSDK_PATH="${ASSETS_PATH}/nopssdk-v1.0.3"
PHYSX_LEGACY_BINARY="${ASSETS_PATH}/PhysX-9.13.0604-SystemSoftware-Legacy.msi"

# Proton toolchain paths
COMPAT_TOOL_PATH="${STEAM_COMPAT_TOOL_PATHS%%:*}"
COMPAT_TOOL_PATH="${COMPAT_TOOL_PATH:-${PROTONPATH}}"
COMPAT_WINE_BINARY="${COMPAT_TOOL_PATH}/files/bin/wine"
COMPAT_WINETRICKS_BINARY="${COMPAT_TOOL_PATH}/protonfixes/winetricks"

# Prefix paths
WINEPREFIX="${WINEPREFIX:-${STEAM_COMPAT_DATA_PATH:+${STEAM_COMPAT_DATA_PATH}/pfx}}"
PREFIX_USER_PATH="${WINEPREFIX}/drive_c/users/steamuser"
PREFIX_ROAMING_PATH="${PREFIX_USER_PATH}/AppData/Roaming"
