# Issue tracker: GitHub Issues

Tickets for this repo live as GitHub issues on paoramati/git-vault, via the `gh` CLI. The factory loop reads them (`TRACKER=github`). They were migrated from beads on 2026-11-21; the id map from old beads ids to issue numbers is `tracker/github-issue-map.json`. `tracker/tickets/*.md` are the original spec files, kept as history and still validated by `ci.sh`; they are no longer the source.

## Conventions

- **Create a ticket**: `gh issue create --title "..." --body-file <file> --label ready-for-agent`. The body ends with a `## Blocked by` section, one `- Blocked by #N` line per blocker, or `None - can start immediately`. A `## Parent` section with `#N` names the epic.
- **Read a ticket**: `gh issue view <n> --comments`.
- **List**: `gh issue list --state open`. The frontier (what the loop will pick): `py <kit>/tracker/gh_tracker.py ready --repo paoramati/git-vault`. Check the blocker lines: `... check --repo paoramati/git-vault`.
- **Comment**: `gh issue comment <n> --body "text"`.
- **Labels**: `gh issue edit <n> --add-label x --remove-label y`. The loop uses `ready-for-agent`, `in-progress` and `ready-for-human`.
- **Close**: `gh issue close <n>`. The loop closes a ticket when it is merged.
- An issue that other issues name under `## Parent` is an epic (like #1) and is never built.
- Agents only run `gh issue view` and `gh issue comment`; the loop alone changes labels and state.

## When a skill says "publish to the issue tracker"

Create a GitHub issue as above.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <n> --comments`.
