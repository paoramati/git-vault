#!/usr/bin/env bats
# bats `load` rejects Windows drive paths (C:/...), so source the helper directly.
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup()    { setup_repo; }
teardown() { teardown_repo; }

@test "version prints the version" {
  run "$VAULT" version
  [ "$status" -eq 0 ]
  [[ "$output" == git-vault\ * ]]
}

@test "help lists every command" {
  run "$VAULT" help
  [ "$status" -eq 0 ]
  for c in lock unlock status backup restore schedule doctor version; do
    [[ "$output" == *"$c"* ]]
  done
}

@test "no arguments shows help" {
  run "$VAULT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"usage: git vault"* ]]
}

@test "unknown command fails with a message" {
  run "$VAULT" nonsense
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown command: nonsense"* ]]
}

@test "runs as a git subcommand when on PATH" {
  # pwd gives /c/... under Git Bash; a C:/... path would be split at the colon in PATH.
  local root; root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  PATH="$root:$PATH" run git vault version
  [ "$status" -eq 0 ]
  [[ "$output" == git-vault\ * ]]
}

@test "each stub command exits 2 with a not-implemented message" {
  for c in lock unlock status backup restore schedule doctor; do
    run "$VAULT" "$c"
    [ "$status" -eq 2 ]
    [[ "$output" == *"git-vault: $c is not implemented yet"* ]]
  done
}

@test "every command in help has lib/cmd_<name>.sh" {
  for c in lock unlock status backup restore schedule doctor; do
    [ -f "$BATS_TEST_DIRNAME/../lib/cmd_$c.sh" ]
  done
}

@test "works via a symlink to the entrypoint" {
  ln -s "$VAULT" "$TEST_ROOT/gv" 2>/dev/null || skip "symlinks unavailable"
  [ -L "$TEST_ROOT/gv" ] || skip "symlinks unavailable"
  run "$TEST_ROOT/gv" lock
  [ "$status" -eq 2 ]
  [[ "$output" == *"lock is not implemented yet"* ]]
}

@test "command names cannot escape lib/" {
  run "$VAULT" ../git-vault
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown command"* ]]
}
