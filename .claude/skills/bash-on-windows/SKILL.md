---
name: bash-on-windows
description: Rules for writing bash that runs in Git Bash on Windows. Use before writing or changing any shell script in this repo.
---

# Bash on Git for Windows

Target: the bash and coreutils that ship with Git for Windows. Also keep it working on Linux bash, because CI may run there.

## Basics
- `set -euo pipefail` at the top. Quote every expansion: `"$var"`, `"${arr[@]}"`.
- Functions use `local`. No global state beyond constants.
- Errors go to stderr through `die`. Exit 0 success, 1 failure, 2 not implemented / bad usage.
- Must pass `shellcheck -x` with no disables unless a comment explains why.

## Paths
- Paths with spaces are normal (`/c/Users/Name/OneDrive - Company/...`). Test with them.
- MSYS rewrites arguments that look like POSIX paths when calling Windows programs (`schtasks.exe`, `cmd.exe`). Use `cygpath -w` to pass Windows paths explicitly, and set `MSYS2_ARG_CONV_EXCL='*'` for that one call when flags like `/Create` get mangled.
- Never assume `/tmp`; use `mktemp -d`.
- Get the absolute path of bash for anything Windows runs later: `cygpath -w "$(command -v bash)"`.

## Files that matter (writes, deletes, renames)
- Write to a temp name in the destination folder, verify, then `mv` into place. Never write the final name directly.
- Sync clients and antivirus lock files briefly. Retry `mv` and `rm` up to 5 times with a short sleep before failing.
- Never delete a file you did not create, and never delete the last valid backup.
- `stat` flags differ by platform; use `ls -t` or `find -newer` for ordering.

## Git
- Use `git -C "$repo"` instead of `cd`.
- Read config with `git config --get`; it exits 1 when unset, so guard it under `set -e`.
- Hooks live at `$(git rev-parse --git-path hooks)`, which also works in worktrees.

## Tests
- One `.bats` file per command. Load `test_helper` and use `setup_repo`.
- Every data-loss guard gets a test that tries to break it.
- Test with a destination containing spaces (`spaced_dest`).
