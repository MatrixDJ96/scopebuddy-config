# Feature flags and handheld helpers
# These helpers control ScopeBuddy auto-features and optional Steam Deck
# spoofing used by some games

# Let ScopeBuddy pick the target resolution automatically
enable_auto_res() {
  export SCB_AUTO_RES=1
}

# Disable automatic resolution management
disable_auto_res() {
  export SCB_AUTO_RES=0
}

# Let ScopeBuddy manage VRR automatically when supported
enable_auto_vrr() {
  export SCB_AUTO_VRR=1
}

# Disable automatic VRR management
disable_auto_vrr() {
  export SCB_AUTO_VRR=0
}

# Let ScopeBuddy enable HDR automatically when a profile asks for it
enable_auto_hdr() {
  export SCB_AUTO_HDR=1
}

# Disable automatic HDR management
disable_auto_hdr() {
  export SCB_AUTO_HDR=0
}

# Spoof Steam Deck mode for games that look for handheld-specific behavior
enable_steam_deck() {
  export SteamDeck=1
}

# Disable Steam Deck spoofing
disable_steam_deck() {
  export SteamDeck=0
}
