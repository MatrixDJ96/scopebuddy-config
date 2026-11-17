# The SCB_AUTO_* variables the launcher reads after the configs.

enable_auto_refresh() {
  export SCB_AUTO_REFRESH=1
}

disable_auto_refresh() {
  export SCB_AUTO_REFRESH=0
}

enable_auto_frame_limit() {
  export SCB_AUTO_FRAME_LIMIT=1
}

disable_auto_frame_limit() {
  export SCB_AUTO_FRAME_LIMIT=0
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
