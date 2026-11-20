#!/usr/bin/env bats
load test_helper

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
  PATH="$BATS_TEST_DIRNAME/..:$PATH" run git vault version
  [ "$status" -eq 0 ]
  [[ "$output" == git-vault\ * ]]
}
