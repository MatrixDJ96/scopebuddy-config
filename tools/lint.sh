#!/usr/bin/env bash
# Lints the shell sources tools/targets.sh lists with shellcheck.
#
# Usage: tools/lint.sh
# Output: shellcheck's findings, nothing when clean.
# Exit status: 0 clean, non-zero on any finding.

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

mapfile -t TARGETS < <(tools/targets.sh)

shellcheck "${TARGETS[@]}"
