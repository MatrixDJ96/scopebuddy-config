#!/usr/bin/env bash
# Lint every shell source in the repository with shellcheck.
# Reads .shellcheckrc for repo-wide overrides.
# Usage: tools/lint.sh

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

mapfile -t TARGETS < <(
  find scripts games tools \
    \( -name '*.sh' -o -name '*.conf' \) \
    -not -name '*.local.conf' \
    -type f
  find . -maxdepth 1 -name '*.conf' -not -name '*.local.conf' -type f
)

shellcheck --shell=bash --external-sources "${TARGETS[@]}"
