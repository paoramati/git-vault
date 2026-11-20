#!/usr/bin/env bash
# ci.sh: the only judge of whether a change is acceptable. Exit non-zero on any failure.
# Runs in Git Bash on Windows and in bash on Linux/macOS.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

step() { printf '\n== %s ==\n' "$*"; }

step "Line endings"
# CRLF in a bash script breaks it under Git Bash.
# git ls-files --eol is reliable here; grep for a CR character matches every file under Git Bash.
bad=$(git ls-files --eol -- git-vault '*.sh' '*.bash' '*.bats' | awk '$2 == "w/crlf" {print $NF}' || true)
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
# The Windows Store "python3" stub exists but fails, so find a Python that actually runs.
PYCMD=()
for c in python3 python "py -3"; do
  # shellcheck disable=SC2086
  if $c -c 'import yaml, jsonschema' >/dev/null 2>&1; then read -r -a PYCMD <<<"$c"; break; fi
done
if [[ ${#PYCMD[@]} -gt 0 ]]; then
  "${PYCMD[@]}" tracker/validate.py tracker/tickets tracker/schema.json
else
  if [[ "${GATE_STRICT:-0}" == 1 ]]; then echo "python with pyyaml+jsonschema is required in strict mode (the factory loop)"; exit 1; fi
  echo "python with pyyaml+jsonschema not available; skipping"
fi

printf '\nci.sh: all checks passed\n'
