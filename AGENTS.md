# Agent rules

## The project

`git-vault` is a single bash script that keeps a git repository local and backed up: it blocks pushing, writes verified bundle backups to a folder (often a synced cloud folder), restores from them, and schedules backups. Users run it as `git vault <command>` from Git Bash on Windows. Data loss is the failure that matters; every mechanic that writes or deletes files needs edge-case tests.

Use the `bash-on-windows` skill (shared, in the Home Repo's `skills/`) before writing any shell or Python code.

## Layout

- `git-vault`: small entrypoint: version, usage, dispatch. Finds `lib/` via its real path (symlink-safe).
- `lib/cmd_<name>.sh`: one file per command, defining `cmd_<name>`. Add a command by adding its file plus one line in the usage text. `lib/common.sh`: shared helpers (`die`, `todo`).
- Release packaging (ticket W-1) builds the single-file install from the entrypoint plus `lib/`. `install.sh` currently copies only the entrypoint, so it works for development in-tree only.
- `tests/*.bats`: one file per command. Use `tests/test_helper.bash`; every test works in a temp repo.
- `ci.sh`: run it. It is the only definition of passing.
- `tracker/tickets/`: the original ticket spec files (history; live tickets are GitHub Issues). `docs/decisions/`: spike outputs.

## Scope

- Work on exactly one ticket: the one in your prompt or in `.agent/current-ticket`.
- File other problems as new tickets. Do not fix them in passing.
- Do not edit `ci.sh`, these rules, or the test helper unless the ticket is about them.

## Git

- Commit locally with messages starting with the ticket ID the loop gives you: `gh-5: verify bundle before rename`.
- Never push, add remotes, or change remote URLs.
- Never rewrite history on main.

## Done means

- Every acceptance criterion has a bats test that would fail without your change.
- `./ci.sh` passes. Run it; do not assume.
- `git vault help` reflects any new options.
- An issue comment (a ticket note) says what changed and what a reviewer should check.

## Never

- Delete or overwrite a user's file without a test proving it is safe.
- Weaken or skip a test to make CI pass.
- Touch any repository outside the test's temp directory.
- Add a dependency beyond bash, git and coreutils that ship with Git for Windows.

## When stuck

Same failure three times: stop, write what you tried and what you suspect in a ticket note, end the session.

## Agent skills

### Issue tracker

GitHub Issues on paoramati/git-vault, via the `gh` CLI; the factory loop reads them. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` plus `docs/decisions/` for decisions. See `docs/agents/domain.md`.
