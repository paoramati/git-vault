#!/usr/bin/env bash
# ci.sh: the only judge of whether a change is acceptable. Exit non-zero on any failure.
# Runs in Git Bash on Windows and in bash on Linux/macOS.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

step() { printf '\n== %s ==\n' "$*"; }

step "Line endings"
# CRLF in a bash script breaks it under Git Bash.
bad=$(git ls-files -z -- git-vault '*.sh' '*.bash' '*.bats' | xargs -0 grep -l $'\r' 2>/dev/null || true)
[[ -z "$bad" ]] || { echo "CRLF found in: $bad"; exit 1; }
echo "ok"

step "ShellCheck"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x git-vault ci.sh install.sh tracker/import-to-beads.sh
else
  echo "shellcheck not installed; skipping (install it to enable this gate)"
fi

step "Tests"
if command -v bats >/dev/null 2>&1; then
  bats tests
else
  npx --yes bats@1.11.0 tests
fi

step "Tickets"
if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml, jsonschema' 2>/dev/null; then
  python3 tracker/validate.py tracker/tickets tracker/schema.json
else
  echo "python3 with pyyaml+jsonschema not available; skipping"
fi

printf '\nci.sh: all checks passed\n'
