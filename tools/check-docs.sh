#!/usr/bin/env bash
# Checks the helper tables of docs/reference.md against the functions scripts/ defines, both
# ways: a function a table names exists, and a public function (no leading _) has a row. A
# function is read from a table row whose first cell holds backticked lowercase identifiers.
#
# Usage: tools/check-docs.sh
#        tools/check-docs.sh --self-test
# Output: one line per mismatch on stderr.
# Exit status: 0 in sync, 1 otherwise.
# The self-test's backticks are Markdown, quoted on purpose.
# shellcheck disable=SC2016
set -euo pipefail

# check_docs <root>
check_docs() {
  (
    cd "$1"
    python3 - <<'PY'
import re, sys
from pathlib import Path

DEF_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\(\)\s*\{")
FN_TOKEN_RE = re.compile(r"`([a-z_][a-z0-9_]*)`")

defined = set()
for sh in sorted(Path("scripts").rglob("*.sh")):
    for line in sh.read_text().splitlines():
        m = DEF_RE.match(line)
        if m:
            defined.add(m.group(1))

public = {f for f in defined if not f.startswith("_")}

documented = set()
ref = Path("docs/reference.md")
for line in ref.read_text().splitlines():
    if not line.startswith("|"):
        continue
    first_cell = line.split("|")[1]
    documented.update(FN_TOKEN_RE.findall(first_cell))

fail = 0

for fn in sorted(documented - defined):
    print(f"docs/reference.md documents `{fn}`, which is not defined in scripts/",
          file=sys.stderr)
    fail = 1

for fn in sorted(public - documented):
    print(f"public function `{fn}` is not documented in docs/reference.md",
          file=sys.stderr)
    fail = 1

sys.exit(fail)
PY
  )
}

self_test_failed() {
  echo "check-docs: self-test: $*" >&2
  exit 1
}

self_test() {
  local dir

  dir=$(mktemp -d)
  # shellcheck disable=SC2064  # expand now: the local is gone at EXIT
  trap "rm -rf '$dir'" EXIT
  mkdir -p "$dir/scripts" "$dir/docs"
  printf 'public_helper() {\n  :\n}\n_private_helper() {\n  :\n}\n' >"$dir/scripts/a.sh"
  printf '| Function | Purpose |\n|---|---|\n| `public_helper` | x |\n' >"$dir/docs/reference.md"

  if ! check_docs "$dir" 2>/dev/null; then
    self_test_failed "the documented layout failed"
  fi

  mkdir -p "$dir/scripts/helpers"
  printf 'nested_helper() {\n  :\n}\n' >"$dir/scripts/helpers/b.sh"
  printf '| `nested_helper` | x |\n' >>"$dir/docs/reference.md"

  if ! check_docs "$dir" 2>/dev/null; then
    self_test_failed "a documented function in a subfolder failed"
  fi

  printf '| `ghost_helper` | x |\n' >>"$dir/docs/reference.md"

  if check_docs "$dir" 2>/dev/null; then
    self_test_failed "a row naming no function passed"
  fi

  printf '| `public_helper` | x |\n' >"$dir/docs/reference.md"

  if check_docs "$dir" 2>/dev/null; then
    self_test_failed "an undocumented public function passed"
  fi

  echo "self-test ok: 1 layout in sync with a subfolder, a ghost row and an undocumented" \
    "function in a subfolder refused"
}

case "${1:-}" in
  --self-test)
    self_test
    ;;
  "")
    check_docs "$(dirname -- "${BASH_SOURCE[0]}")/.."
    ;;
  *)
    echo "check-docs: usage: tools/check-docs.sh [--self-test]" >&2
    exit 1
    ;;
esac
