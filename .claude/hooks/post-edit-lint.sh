#!/usr/bin/env bash
# post-edit-lint.sh — PostToolUse validator, matcher "Edit|Write".
# TEMPLATE: the scaffolder (or the operator) fills the two placeholders below with the
# repo's REAL lint gate before wiring it. Wire this hook ONLY when such a gate exists.
#
#   scope   scripts/ and games/ shell sources (*.sh, *.conf), *.local.conf excluded
#   command shellcheck, which reads the repo .shellcheckrc (shell=bash, external-sources)
#
# Behavior: fail-open when the lint tool is unavailable (a missing dependency must not
# block every edit); exit 2 ONLY on a true lint error so Claude fixes the file it just wrote.

set -uo pipefail

PAYLOAD="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0   # fail open without jq

TARGET_PATH="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty')"
[ -n "$TARGET_PATH" ] && [ -f "$TARGET_PATH" ] || exit 0

# Scope mirrors tools/lint.sh: shell sources under scripts/ and games/, local overrides aside.
case "$TARGET_PATH" in
  *.local.conf) exit 0 ;;
  */scripts/*.sh | */scripts/*.conf | */games/*.sh | */games/*.conf) ;;
  *) exit 0 ;;
esac

LINT_CMD="shellcheck"
if ! command -v "${LINT_CMD%% *}" >/dev/null 2>&1; then
  # Lint tool unavailable in this environment: fail open, one visible warning.
  echo "WARNING: '${LINT_CMD%% *}' not found — post-edit lint skipped for $TARGET_PATH." >&2
  exit 0
fi

OUTPUT="$($LINT_CMD "$TARGET_PATH" 2>&1)" && exit 0

echo "LINT ERROR in $TARGET_PATH — fix it before proceeding:" >&2
echo "$OUTPUT" >&2
exit 2
