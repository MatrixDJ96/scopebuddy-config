#!/usr/bin/env python3
"""PostToolUse hook: run the repo's own linter on the file just written.

Wire it in .claude/settings.json under hooks.PostToolUse with matcher "Write|Edit".
The linter is recognised by the config file the repo carries, the file by its suffix or, without
one, by its shebang; the linter binary is looked up in the repo's .venv/bin (Scripts on
Windows), then at the repo root, then on PATH, and every linter that matches the file runs.
Findings go back to the model through exit 2, whose stderr Claude sees. Without findings, a
linter found but unable to start is named in one line through exit 1, which the user sees as a
hook error and Claude does not. Fails open: no linter, no config, no match — exit 0 and nothing
said.
"""

import json
import os
import shutil
import subprocess
import sys

# config at the repo root -> (command, file suffixes, shebang interpreters for a suffixless file)
LINTERS = (
    ((".shellcheckrc",), ["shellcheck"], (".sh", ".bash", ".conf"),
     ("sh", "bash", "dash", "ksh")),  # the shells shellcheck accepts; zsh it refuses
    (("ruff.toml", ".ruff.toml", "pyproject.toml"), ["ruff", "check", "--quiet"], (".py",),
     ("python", "python3")),
    (("eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", ".eslintrc",
      ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs"),
     ["node_modules/.bin/eslint"], (".js", ".jsx", ".ts", ".tsx"), ()),
    (("phpstan.neon", "phpstan.neon.dist"),
     ["vendor/bin/phpstan", "analyse", "--no-progress", "--error-format=raw"], (".php",), ()),
)
VENV_BIN = os.path.join(".venv", "Scripts" if os.name == "nt" else "bin")
# On Windows a linter is ruff.exe or eslint.cmd, and its extensionless sibling cannot start.
EXTENSIONS = ([e for e in os.environ.get("PATHEXT", ".COM;.EXE;.BAT;.CMD").split(";") if e]
              if os.name == "nt" else [""])


def configured(root, name):
    """The config file sits at the repo root; a pyproject.toml counts only with a [tool.ruff]
    table, the one linter config it can carry here."""
    path = os.path.join(root, name)
    if name != "pyproject.toml":
        return os.path.isfile(path)
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return "[tool.ruff" in f.read()
    except OSError:
        return False


def interpreter(path):
    """The interpreter a `#!` first line names — its first word, `env`'s argument when the
    line goes through env — or None; an unreadable file is no match, the hook fails open."""
    try:
        with open(path, "rb") as f:
            first = f.readline(200)
    except OSError:
        return None
    if not first.startswith(b"#!"):
        return None
    words = first[2:].decode("ascii", "replace").split()
    if words and os.path.basename(words[0]) == "env":
        words = [w for w in words[1:] if not w.startswith("-")]
    return os.path.basename(words[0]) if words else None


def executable(root, exe):
    """The repo's venv, then the repo root, then PATH — the pinned linter before the host's, so
    the hook and the repo's own gate report the same findings; None when it is nowhere."""
    for base in (os.path.join(root, VENV_BIN, exe), os.path.join(root, exe)):
        for candidate in (base + ext for ext in EXTENSIONS):
            if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
                return candidate
    # PATH holds bare names; which() would resolve vendor/bin/phpstan from the working directory
    return shutil.which(exe) if os.path.basename(exe) == exe else None


def repo_root(directory):
    """The top of the git repository holding directory; None outside one or without git."""
    try:
        top = subprocess.run(["git", "-C", directory, "rev-parse", "--show-toplevel"],
                             capture_output=True)
    except OSError:
        return None
    return os.fsdecode(top.stdout.rstrip(b"\n")) if top.returncode == 0 else None


def main():
    if os.name == "posix" and sys.getfilesystemencoding() != "utf-8":
        # The client's paths are UTF-8, which outside UTF-8 Mode no file name or argument keeps.
        os.execv(sys.executable, [sys.executable, "-X", "utf8", *sys.argv])
    try:
        payload = json.loads(sys.stdin.buffer.read())
    except (ValueError, RecursionError):
        return 0
    tool_input = payload.get("tool_input") if isinstance(payload, dict) else None
    target = tool_input.get("file_path") if isinstance(tool_input, dict) else None
    if not isinstance(target, str) or not os.path.isfile(target):
        return 0
    if target.endswith(".local.conf"):  # machine-specific overrides, excluded like tools/lint.sh
        return 0
    # git names the root by its real path; the header and the linter take the file's too
    real = os.path.join(os.path.realpath(os.path.dirname(target)), os.path.basename(target))
    root = repo_root(os.path.dirname(real))
    if root is None:
        return 0
    has_suffix = "." in os.path.basename(target)
    findings, broken = [], []
    for configs, command, suffixes, interpreters in LINTERS:
        if not any(configured(root, c) for c in configs):
            continue
        if has_suffix and not target.endswith(suffixes):
            continue
        if not has_suffix and interpreter(target) not in interpreters:
            continue
        exe = executable(root, command[0])
        if exe is None:
            continue
        cannot = f"lint-hook: {exe} cannot start: ".encode("utf-8", "backslashreplace")
        try:
            run = subprocess.run([exe] + command[1:] + [real], cwd=root, capture_output=True)
        except OSError as error:  # found but cannot start, as a venv whose interpreter is gone
            broken.append(cannot + error.strerror.encode("utf-8", "backslashreplace") + b"\n")
            continue
        if run.returncode in (126, 127):  # env and sh: an interpreter not found or not runnable
            lines = run.stderr.strip().splitlines()
            broken.append(cannot + (lines[-1] if lines else b"exit %d" % run.returncode) + b"\n")
        elif run.returncode != 0:
            findings.append(run.stdout + run.stderr)
    if findings:
        header = f"lint findings in {os.path.relpath(real, root)}:\n"
        sys.stderr.buffer.write(header.encode("utf-8", "backslashreplace") + b"".join(findings)
                                + b"\n")
        return 2
    if broken:
        sys.stderr.buffer.write(b"".join(broken))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
