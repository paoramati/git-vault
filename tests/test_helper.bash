# Shared setup for bats tests.
# Every test gets a fresh temporary repo and never touches the developer's real repos.

VAULT="$BATS_TEST_DIRNAME/../git-vault"

setup_repo() {
  TEST_ROOT="$(mktemp -d)"
  REPO="$TEST_ROOT/repo"
  git init -q "$REPO"
  git -C "$REPO" config user.email test@example.com
  git -C "$REPO" config user.name "Test"
  git -C "$REPO" config core.autocrlf false
  echo "first" > "$REPO/file.txt"
  git -C "$REPO" add file.txt
  git -C "$REPO" commit -qm "first commit"
  cd "$REPO"
}

teardown_repo() {
  cd /
  [[ -n "${TEST_ROOT:-}" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}

# A destination path with a space, like a synced cloud folder.
spaced_dest() {
  local d="$TEST_ROOT/Cloud Drive/backups"
  mkdir -p "$d"
  printf '%s' "$d"
}
