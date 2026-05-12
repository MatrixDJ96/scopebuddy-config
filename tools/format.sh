#!/usr/bin/env bash
# Formats the shell sources tools/targets.sh lists with shfmt.
#
# Usage: tools/format.sh          rewrite the files in place
#        tools/format.sh --check  print the diffs, write nothing
# Output: with --check, a unified diff per file that would change.
# Exit status: 0 clean or rewritten; 1 with --check when a file would change, or on an unknown
# argument.

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

SHFMT_ARGS=(--indent 2 --case-indent --simplify --binary-next-line)

case "${1:-}" in
  --check)
    SHFMT_ARGS+=(-d)
    ;;
  "")
    SHFMT_ARGS+=(-w)
    ;;
  *)
    echo "format: usage: tools/format.sh [--check]" >&2
    exit 1
    ;;
esac

mapfile -t TARGETS < <(tools/targets.sh)

shfmt "${SHFMT_ARGS[@]}" "${TARGETS[@]}"
