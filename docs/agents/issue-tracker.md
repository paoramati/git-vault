# Issue tracker: beads

Tickets for this repo live in beads (`bd`), a local Dolt store in the git-ignored `.beads/` folder. The factory loop reads it. The ticket source files in `tracker/tickets/*.md` are validated by `ci.sh` and imported with `tracker/import-to-beads.sh`; GitHub is a published mirror, not the source.

## Conventions

- **Create a ticket**: write `tracker/tickets/<ID>.md`, then run the importer. For a one-off, `bd create "title" -t <type> -p <0-4> --body-file <file>`. Pass long text with `--body-file`; `-d` mangles text starting with `---`.
- **Read a ticket**: `bd show <id>` (add `--json`). Dependencies and notes appear in the output.
- **List**: `bd list` (all open), `bd ready --label agent-ok` (the frontier: unblocked, agent-safe), `bd list --all` (include closed).
- **Comment**: `bd comments add <id> "text"`.
- **Labels**: `bd label add <id> label1,label2`.
- **Status**: `bd update <id> --status open|in_progress|blocked|closed`; `bd close <id>`.
- **Blocking**: `bd dep add <ticket> <blocker>`; parent link with `--type parent-child`.
- **Run from any worktree**: set `BEADS_DIR` to the main repo's `.beads` (the loop does this).
- **Remotes**: use `bd dolt push --remote private --no-adopt`. Leave `--yes` off: it can adopt the public GitHub remote.

## When a skill says "publish to the issue tracker"

Add a ticket source file under `tracker/tickets/` and import it, so `ci.sh` validates it.

## When a skill says "fetch the relevant ticket"

Run `bd show <id>`.
