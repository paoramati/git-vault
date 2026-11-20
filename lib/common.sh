# Shared helpers, sourced by the git-vault entrypoint.

die()  { printf 'git-vault: %s\n' "$*" >&2; exit 1; }
todo() { printf 'git-vault: %s is not implemented yet\n' "$1" >&2; exit 2; }

# --- push locking (used by cmd_lock and cmd_unlock) ---
# Not a valid URL scheme: any push to it fails with "unable to find remote helper".
VAULT_LOCK_URL="git-vault-locked://pushing-disabled"
VAULT_HOOK_MARK="# git-vault pre-push guard"

# Fail unless inside a git repo. Run once at the start of a command.
require_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
}

# Absolute hooks dir; shared by all worktrees of a repo.
vault_hooks_dir() {
  local d; d="$(git rev-parse --git-path hooks)"
  [[ "$d" == /* || "$d" =~ ^[A-Za-z]:/ ]] || d="$(pwd)/$d"
  printf '%s' "$d"
}
