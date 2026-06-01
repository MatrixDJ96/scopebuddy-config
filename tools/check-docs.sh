#!/usr/bin/env bash
# Keep docs/reference.md in sync with the functions defined in scripts/.
#
# Two checks, both line-number free:
#   1. Every function named in a reference.md helper table exists in scripts/.
#   2. Every public function in scripts/ (not prefixed with _) is documented in
#      a reference.md helper table.
#
# Functions are read from table rows whose first cell holds backticked
# lowercase identifiers, e.g. | `enable_auto_res` / `disable_auto_res` | ... |.
# Uppercase first cells (globals, variables) are ignored.
#
# Exit codes:
#   0  reference.md and scripts/ agree
#   1  a documented function is missing, or a public function is undocumented
#
# Usage: tools/check-docs.sh

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

python3 - <<'PY'
import re, sys
from pathlib import Path

DEF_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\(\)\s*\{")
FN_TOKEN_RE = re.compile(r"`([a-z_][a-z0-9_]*)`")

defined = set()
for sh in sorted(Path("scripts").glob("*.sh")):
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
