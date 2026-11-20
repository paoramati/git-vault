# Agent rules

## The project
`git-vault` is a single bash script that keeps a git repository local and backed up: it blocks pushing, writes verified bundle backups to a folder (often a synced cloud folder), restores from them, and schedules backups. Users run it as `git vault <command>` from Git Bash on Windows. Data loss is the failure that matters; every mechanic that writes or deletes files needs edge-case tests.

Read `.claude/skills/bash-on-windows/SKILL.md` before writing any shell code.

## Layout
- `git-vault`: the whole tool. One file, one function per command (`cmd_<name>`), dispatched from `main`.
- `tests/*.bats`: one file per command. Use `tests/test_helper.bash`; every test works in a temp repo.
- `ci.sh`: run it. It is the only definition of passing.
- `tracker/tickets/`: ticket source files. `docs/decisions/`: spike outputs.

## Scope
- Work on exactly one ticket: the one in your prompt or in `.agent/current-ticket`.
- File other problems as new tickets. Do not fix them in passing.
- Do not edit `ci.sh`, these rules, or the test helper unless the ticket is about them.

## Git
- Commit locally with messages starting with the ticket ID: `M-2: verify bundle before rename`.
- Never push, add remotes, or change remote URLs.
- Never rewrite history on main.

## Done means
- Every acceptance criterion has a bats test that would fail without your change.
- `./ci.sh` passes. Run it; do not assume.
- `git vault help` reflects any new options.
- A ticket note says what changed and what a reviewer should check.

## Never
- Delete or overwrite a user's file without a test proving it is safe.
- Weaken or skip a test to make CI pass.
- Touch any repository outside the test's temp directory.
- Add a dependency beyond bash, git and coreutils that ship with Git for Windows.

## When stuck
Same failure three times: stop, write what you tried and what you suspect in a ticket note, end the session.
