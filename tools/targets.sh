#!/usr/bin/env bash
# Lists the shell sources the gates read: scripts/, games/, tools/, tests/ and the root profile
# configs, the *.local.* layers excluded.
#
# Usage: tools/targets.sh
# Output: one path per line, relative to the repository root.
# Exit status: 0; find's own on an unreadable directory.
set -euo pipefail

cd "$(dirname -- "${BASH_SOURCE[0]}")/.."

find scripts games tools tests \
  \( -name '*.sh' -o -name '*.conf' -o -name '*.env' \) \
  -not -name '*.local.conf' -not -name '*.local.env' \
  -type f
find . -maxdepth 1 -name '*.conf' -not -name '*.local.conf' -type f
