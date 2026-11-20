# git-vault

Keep a git repository local and backed up.

- **Lock it:** `git vault lock` stops pushes from the repository, so nothing reaches a remote by accident.
- **Back it up:** `git vault backup <folder>` writes a single verified bundle file with the full history, plus a patch of uncommitted changes. Point it at a synced cloud folder.
- **Restore it:** `git vault restore <folder> <dir>` clones the newest valid backup.
- **Schedule it:** `git vault schedule <folder>` runs backups automatically through Windows Task Scheduler.
- **Check it:** `git vault status` and `git vault doctor`.

Bundles, not a bare repo, because a sync client can upload a bare repo's many small files mid-write and corrupt it. A bundle is one file, written under a temporary name and renamed only after it verifies.

## Status

Early. Only `version` and `help` work. The rest are tickets in `tracker/tickets/`, being built by AI coding agents as a proof of concept.

## Install

Requires Git for Windows (Git Bash). Also runs in bash on Linux and macOS.

```bash
./install.sh          # copies git-vault to ~/bin
git vault version
```

## Development

```bash
./ci.sh               # line endings, shellcheck (if installed), bats tests, ticket schema
```

Tests use bats-core; `ci.sh` falls back to `npx bats` if it is not installed.

## License

MIT
