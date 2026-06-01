# ScopeBuddy bootstrap: load the shared modules in dependency order

# Foundation: paths and shared utilities
source "${SCB_CONFIGDIR}/scripts/paths.sh"
source "${SCB_CONFIGDIR}/scripts/utils.sh"

# Launch state: launcher, feature toggles, gamescope, MangoHud
source "${SCB_CONFIGDIR}/scripts/launcher.sh"
source "${SCB_CONFIGDIR}/scripts/features.sh"
source "${SCB_CONFIGDIR}/scripts/gamescope.sh"
source "${SCB_CONFIGDIR}/scripts/mangohud.sh"

# Proton, Wine and GPU helpers
source "${SCB_CONFIGDIR}/scripts/proton.sh"
source "${SCB_CONFIGDIR}/scripts/wine.sh"
source "${SCB_CONFIGDIR}/scripts/graphics.sh"

# Game resolution, filesystem and asset helpers
source "${SCB_CONFIGDIR}/scripts/game.sh"
source "${SCB_CONFIGDIR}/scripts/filesystem.sh"
source "${SCB_CONFIGDIR}/scripts/assets.sh"

# Orchestration: profile defaults and config loaders
source "${SCB_CONFIGDIR}/scripts/profiles.sh"
source "${SCB_CONFIGDIR}/scripts/configs.sh"
