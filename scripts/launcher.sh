# Helpers for SCB_AUTO_* variables read directly by the ScopeBuddy launcher
# to drive gamescope -r (refresh) and --framerate-limit

# Toggle the launcher's gamescope -r from the detected refresh rate (1 on, 0 off)
set_auto_refresh() {
  export SCB_AUTO_REFRESH="$1"
}

# Clear the refresh-rate toggle
unset_auto_refresh() {
  unset SCB_AUTO_REFRESH
}

# Toggle the launcher's gamescope --framerate-limit from the detected refresh rate (1 on, 0 off)
set_auto_frame_limit() {
  export SCB_AUTO_FRAME_LIMIT="$1"
}

# Clear the framerate-limit toggle
unset_auto_frame_limit() {
  unset SCB_AUTO_FRAME_LIMIT
}
