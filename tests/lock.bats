#!/usr/bin/env bats
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup()    { setup_repo; }
teardown() { teardown_repo; }

# Add a bare remote named $1 inside TEST_ROOT.
add_remote() {
  git init -q --bare "$TEST_ROOT/$1.git"
  git remote add "$1" "$TEST_ROOT/$1.git"
}

cfg() { git config --local --list | sort; }

@test "lock outside a git repo fails with exit 1" {
  cd "$TEST_ROOT"
  run "$VAULT" lock
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a git repository"* ]]
  run "$VAULT" unlock
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a git repository"* ]]
}

@test "lock blocks push to an existing remote" {
  add_remote origin
  "$VAULT" lock
  run git push origin HEAD
  [ "$status" -ne 0 ]
  [ -z "$(git -C "$TEST_ROOT/origin.git" for-each-ref)" ]
}

@test "lock blocks push to a remote added after locking" {
  "$VAULT" lock
  add_remote late
  run git push late HEAD
  [ "$status" -ne 0 ]
  [ -z "$(git -C "$TEST_ROOT/late.git" for-each-ref)" ]
}

@test "layer 1 alone (no hook) blocks pushes, including later remotes and raw URLs" {
  add_remote origin
  "$VAULT" lock
  rm -f "$(git rev-parse --git-path hooks)/pre-push"
  run git push origin HEAD
  [ "$status" -ne 0 ]
  add_remote late
  run git push late HEAD
  [ "$status" -ne 0 ]
  run git push "$TEST_ROOT/late.git" HEAD
  [ "$status" -ne 0 ]
  [ -z "$(git -C "$TEST_ROOT/late.git" for-each-ref)" ]
}

@test "layer 2 alone (hook only) blocks pushes" {
  add_remote origin
  "$VAULT" lock
  git config --unset-all remote.origin.pushurl
  git config --remove-section "url.git-vault-locked://pushing-disabled"
  run git push origin HEAD
  [ "$status" -ne 0 ]
  [[ "$output" == *"pushing is locked"* ]]
  [ -z "$(git -C "$TEST_ROOT/origin.git" for-each-ref)" ]
}

@test "fetch still works with the original URL when locked" {
  add_remote origin
  git push -q origin HEAD:refs/heads/main
  local url; url="$(git remote get-url origin)"
  "$VAULT" lock
  run git fetch origin
  [ "$status" -eq 0 ]
  [ "$(git remote get-url origin)" = "$url" ]
}

@test "unlock restores push ability and exact config" {
  add_remote origin
  local before; before="$(cfg)"
  "$VAULT" lock
  "$VAULT" unlock
  [ "$(cfg)" = "$before" ]
  run git push origin HEAD:refs/heads/main
  [ "$status" -eq 0 ]
  [ -n "$(git -C "$TEST_ROOT/origin.git" for-each-ref)" ]
  [ ! -e "$(git rev-parse --git-path hooks)/pre-push" ]
}

@test "repo with no remotes: lock and unlock work" {
  local before; before="$(cfg)"
  run "$VAULT" lock
  [ "$status" -eq 0 ]
  run "$VAULT" unlock
  [ "$status" -eq 0 ]
  [ "$(cfg)" = "$before" ]
}

@test "explicit pushurl is preserved across lock/unlock" {
  add_remote origin
  git init -q --bare "$TEST_ROOT/other.git"
  git config remote.origin.pushurl "$TEST_ROOT/other.git"
  local before; before="$(cfg)"
  local pu; pu="$(git config remote.origin.pushurl)"
  "$VAULT" lock
  run git push origin HEAD
  [ "$status" -ne 0 ]
  [ "$(git config --get-all vault.origin.pushurl)" = "$pu" ]
  "$VAULT" unlock
  [ "$(cfg)" = "$before" ]
  run git push origin HEAD:refs/heads/main
  [ "$status" -eq 0 ]
  [ -n "$(git -C "$TEST_ROOT/other.git" for-each-ref)" ]
  [ -z "$(git -C "$TEST_ROOT/origin.git" for-each-ref)" ]
}

@test "several pushurls on one remote are all restored in order" {
  add_remote origin
  git config --add remote.origin.pushurl "$TEST_ROOT/a.git"
  git config --add remote.origin.pushurl "$TEST_ROOT/b.git"
  local before; before="$(cfg)"
  "$VAULT" lock
  [ "$(git config --get-all remote.origin.pushurl)" = "git-vault-locked://pushing-disabled" ]
  "$VAULT" unlock
  [ "$(cfg)" = "$before" ]
}

@test "several remotes are all locked and restored" {
  add_remote one
  add_remote two
  git config remote.two.pushurl "$TEST_ROOT/one.git"
  local before; before="$(cfg)"
  "$VAULT" lock
  run git push one HEAD
  [ "$status" -ne 0 ]
  run git push two HEAD
  [ "$status" -ne 0 ]
  "$VAULT" unlock
  [ "$(cfg)" = "$before" ]
}

@test "lock is idempotent and does not clobber saved originals" {
  add_remote origin
  git config remote.origin.pushurl "$TEST_ROOT/other.git"
  local before; before="$(cfg)"
  "$VAULT" lock
  local locked; locked="$(cfg)"
  run "$VAULT" lock
  [ "$status" -eq 0 ]
  [ "$(cfg)" = "$locked" ]
  "$VAULT" unlock
  [ "$(cfg)" = "$before" ]
}

@test "unlock is idempotent and works when never locked" {
  add_remote origin
  local before; before="$(cfg)"
  run "$VAULT" unlock
  [ "$status" -eq 0 ]
  "$VAULT" lock
  "$VAULT" unlock
  run "$VAULT" unlock
  [ "$status" -eq 0 ]
  [ "$(cfg)" = "$before" ]
}

@test "existing pre-push hook is preserved while locked and restored on unlock" {
  add_remote origin
  local h; h="$(git rev-parse --git-path hooks)/pre-push"
  mkdir -p "$(dirname "$h")"
  printf '#!/bin/sh\n# my hook\nexit 0\n' > "$h"
  chmod +x "$h"
  local sum; sum="$(cksum < "$h")"
  "$VAULT" lock
  run git push origin HEAD
  [ "$status" -ne 0 ]
  [ -f "$h.vault-orig" ]
  [ "$(cksum < "$h.vault-orig")" = "$sum" ]
  "$VAULT" lock   # second lock must not move the guard over the user hook
  [ "$(cksum < "$h.vault-orig")" = "$sum" ]
  "$VAULT" unlock
  [ "$(cksum < "$h")" = "$sum" ]
  [ ! -e "$h.vault-orig" ]
}

@test "unlock keeps a hook the user replaced while locked, and warns" {
  local h; h="$(git rev-parse --git-path hooks)/pre-push"
  mkdir -p "$(dirname "$h")"
  printf '#!/bin/sh\n# original\nexit 0\n' > "$h"
  "$VAULT" lock
  printf '#!/bin/sh\n# replaced\nexit 0\n' > "$h"
  run "$VAULT" unlock
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning"* ]]
  grep -q replaced "$h"
  grep -q original "$h.vault-orig"
}

@test "lock refuses to overwrite an existing pre-push.vault-orig" {
  local h; h="$(git rev-parse --git-path hooks)/pre-push"
  mkdir -p "$(dirname "$h")"
  echo '#!/bin/sh' > "$h"
  echo 'precious' > "$h.vault-orig"
  run "$VAULT" lock
  [ "$status" -eq 1 ]
  grep -q precious "$h.vault-orig"
  [ ! -s "$h" ] || ! grep -qF "git-vault pre-push guard" "$h"
}

@test "works inside a linked worktree and locks the whole repo" {
  add_remote origin
  git worktree add -q "$TEST_ROOT/wt" -b wtbranch
  cd "$TEST_ROOT/wt"
  run "$VAULT" lock
  [ "$status" -eq 0 ]
  run git push origin HEAD
  [ "$status" -ne 0 ]
  cd "$REPO"
  run git push origin HEAD
  [ "$status" -ne 0 ]
  cd "$TEST_ROOT/wt"
  "$VAULT" unlock
  run git push origin HEAD:refs/heads/main
  [ "$status" -eq 0 ]
}

@test "works when the repo path contains spaces" {
  local sp="$TEST_ROOT/with space"
  git init -q "$sp"
  git -C "$sp" config user.email t@example.com
  git -C "$sp" config user.name T
  git -C "$sp" commit -q --allow-empty -m x
  git init -q --bare "$TEST_ROOT/r.git"
  git -C "$sp" remote add origin "$TEST_ROOT/r.git"
  cd "$sp"
  "$VAULT" lock
  run git push origin HEAD
  [ "$status" -ne 0 ]
  "$VAULT" unlock
  run git push origin HEAD:refs/heads/main
  [ "$status" -eq 0 ]
}
