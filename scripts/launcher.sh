# Helpers for SCB_AUTO_* variables read directly by the ScopeBuddy launcher
# to drive gamescope -r (refresh) and --framerate-limit

# Set the gamescope refresh-rate target (-r)
set_auto_refresh() {
  export SCB_AUTO_REFRESH="$1"
}

# Clear the gamescope refresh-rate target
unset_auto_refresh() {
  unset SCB_AUTO_REFRESH
}

# Set the gamescope framerate cap (--framerate-limit)
set_auto_frame_limit() {
  export SCB_AUTO_FRAME_LIMIT="$1"
}

# Clear the gamescope framerate cap
unset_auto_frame_limit() {
  unset SCB_AUTO_FRAME_LIMIT
}
