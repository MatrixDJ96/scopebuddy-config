#!/usr/bin/env python3
"""PostToolUse hook: run the repo's own linter on the file just written.

Wire it in .claude/settings.json under hooks.PostToolUse with matcher "Write|Edit".
The linter is recognised by the config file the repo carries; findings go back to the
model through exit 2 (the only PostToolUse channel that reaches it). Fails open: no
linter, no config, no match — exit 0 and nothing said.
"""

import json
import os
import shutil
import subprocess
import sys

# config file present at the repo root -> (command, file suffixes it applies to)
LINTERS = (
    ((".shellcheckrc",), ["shellcheck"], (".sh", ".bash", ".conf")),
    (("ruff.toml", ".ruff.toml"), ["ruff", "check", "--quiet"], (".py",)),
    (("eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", ".eslintrc",
      ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs"),
     ["npx", "--no-install", "eslint"], (".js", ".jsx", ".ts", ".tsx")),
    (("phpstan.neon", "phpstan.neon.dist"),
     ["vendor/bin/phpstan", "analyse", "--no-progress", "--error-format=raw"], (".php",)),
)


def main():
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0
    target = (payload.get("tool_input") or {}).get("file_path")
    if not target or not os.path.isfile(target):
        return 0
    if target.endswith(".local.conf"):  # machine-specific overrides, excluded like tools/lint.sh
        return 0
    top = subprocess.run(["git", "-C", os.path.dirname(target), "rev-parse",
                          "--show-toplevel"], capture_output=True, text=True)
    if top.returncode != 0:
        return 0
    root = top.stdout.strip()
    for configs, command, suffixes in LINTERS:
        if not any(os.path.isfile(os.path.join(root, c)) for c in configs):
            continue
        if not target.endswith(suffixes):
            return 0
        exe = command[0]
        if not (shutil.which(exe) or os.path.isfile(os.path.join(root, exe))):
            return 0
        run = subprocess.run(command + [target], cwd=root, capture_output=True, text=True)
        if run.returncode == 0:
            return 0
        print(f"lint findings in {os.path.relpath(target, root)}:\n"
              f"{run.stdout}{run.stderr}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
