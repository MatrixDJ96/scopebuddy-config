#!/usr/bin/env bash
# Format every shell source in the repository with shfmt.
# Usage:
#   tools/format.sh          # rewrite files in place
#   tools/format.sh --check  # diff-only mode (CI-friendly), exit 1 on diff

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

SHFMT_ARGS=(
  -i 2 # indent: 2 spaces
  -ci  # indent switch cases
  -s   # simplify
  -bn  # binary ops at beginning of next line
)

if [[ ${1:-} == "--check" ]]; then
  SHFMT_ARGS+=(-d)
else
  SHFMT_ARGS+=(-w)
fi

mapfile -t TARGETS < <(
  find scripts games tools \
    \( -name '*.sh' -o -name '*.conf' \) \
    -not -name '*.local.conf' \
    -type f
  find . -maxdepth 1 -name '*.conf' -not -name '*.local.conf' -type f
)

shfmt "${SHFMT_ARGS[@]}" "${TARGETS[@]}"
