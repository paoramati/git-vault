# Shared helpers, sourced by the git-vault entrypoint.

die()  { printf 'git-vault: %s\n' "$*" >&2; exit 1; }
todo() { printf 'git-vault: %s is not implemented yet\n' "$1" >&2; exit 2; }
