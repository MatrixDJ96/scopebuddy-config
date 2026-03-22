# The SCB_AUTO_* variables the launcher reads after the configs.

# set_auto_refresh <0|1>
set_auto_refresh() {
  export SCB_AUTO_REFRESH="$1"
}

unset_auto_refresh() {
  unset SCB_AUTO_REFRESH
}

# set_auto_frame_limit <0|1>
set_auto_frame_limit() {
  export SCB_AUTO_FRAME_LIMIT="$1"
}

unset_auto_frame_limit() {
  unset SCB_AUTO_FRAME_LIMIT
}

enable_auto_res() {
  export SCB_AUTO_RES=1
}

disable_auto_res() {
  export SCB_AUTO_RES=0
}

enable_auto_vrr() {
  export SCB_AUTO_VRR=1
}

disable_auto_vrr() {
  export SCB_AUTO_VRR=0
}

enable_auto_hdr() {
  export SCB_AUTO_HDR=1
}

disable_auto_hdr() {
  export SCB_AUTO_HDR=0
}
