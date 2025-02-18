#!/usr/bin/env bats

setup_file() {
  load "helpers/common-setup.bash"
  _common_setup_file
}

teardown_file() {
  load "helpers/common-setup.bash"
  _common_teardown_file
}

setup() {
  load "helpers/common-setup.bash"
  _common_setup
}

teardown() {
  load "helpers/common-setup.bash"
  _common_teardown
}

# bats test_tags=no-repository
@test "git whoami -h should print help" {
  run git whoami -h

  [ $status -eq 0 ]
  [ -n "$output" ]
}

# bats test_tags=no-repository
@test "git whoami should print current user" {
  local git_config=(-c "user.name=John Doe" -c "user.email=john.doe@example.com")

  run git "${git_config[@]}" whoami

  [ $status -eq 0 ]
  [ "$output" == "John Doe <john.doe@example.com>" ]
}

# bats test_tags=no-repository
@test "git whoami -s should print name of the current user" {
  local git_config=(-c "user.name=John Doe" -c "user.email=john.doe@example.com")

  run git "${git_config[@]}" whoami -s

  [ $status -eq 0 ]
  [ "$output" == "John Doe" ]
}

@test "git whoami should print current user inside a git repository" {
  git config user.name "Jane Doe"
  git config user.email "jane.doe@example.com"

  run git whoami

  [ $status -eq 0 ]
  [ "$output" == "Jane Doe <jane.doe@example.com>" ]
}

@test "git whoami -s should print name of the current user inside a git repository" {
  git config user.name "Jane Doe"
  git config user.email "jane.doe@example.com"

  run git whoami -s

  [ $status -eq 0 ]
  [ "$output" == "Jane Doe" ]
}
