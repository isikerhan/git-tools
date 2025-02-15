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
@test "git squash -h should print help" {
  run git squash -h

  [ $status -eq 0 ]
  [ -n "$output" ]
}

@test "git squash should squash commits onto given base commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"

  local base_commit="$(git show -s --format=%H HEAD~3)"
  run git squash HEAD~3 -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ "$base_commit" == "$(git show -s --format=%H HEAD~1)" ]
  [ "$(printf "file2.txt\nfile3.txt\nfile4.txt")" == "$(git diff HEAD~1..HEAD --name-only)" ]
}

@test "git squash -n should squash latest n commits" {
  local n=4

  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  local base_commit="$(git show -s --format=%H "HEAD~$n")"
  run git squash -n $n -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ "$base_commit" == "$(git show -s --format=%H HEAD~1)" ]
  [ "$(printf "file2.txt\nfile3.txt\nfile4.txt\nfile5.txt")" == "$(git diff HEAD~1..HEAD --name-only)" ]
}

@test "git squash --root should squash the whole history into a single commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  run git squash --root -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 1 ]
}

@test "git squash should use the given message as the commit log message" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  local message="This is a test log message!"
  run git squash -n 3 -m "$message"

  [ $status -eq 0 ]
  [ "$message" == "$(git show -s --format=%s HEAD)" ]
}

@test "git squash with --no-commit should squash the commits but not create a commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  run git squash --no-commit -n 3 -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 2 ]
  [ "$(printf "A  file3.txt\nA  file4.txt\nA  file5.txt")" == "$(git status --porcelain)" ]
}

@test "git squash with --edit should allow editing commit log message even if a message is already provided" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  local message="This is a test log message!"
  local config=(-c "core.editor=echo $message >")
  run git "${config[@]}" squash -n 3 --edit -m "This message will be overwritten"

  [ $status -eq 0 ]
  [ "$message" == "$(git show -s --format=%s HEAD)" ]
}

@test "git squash should fail when squashed commits introduce no change" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file4.txt && git add file4.txt && git commit -m "update file4"
  git rm file4.txt && git commit -m "remove file4"

  local head="$(git show -s --format=%H)"
  run git squash -n 3 -m "squash test"

  [ $status -ne 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 6 ]
  [[ $output == *"error: squash ended up in an empty changeset. aborting"* ]] || false
}

@test "git squash with --empty=abort should fail when squashed commits introduce no change" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file4.txt && git add file4.txt && git commit -m "update file4"
  git rm file4.txt && git commit -m "remove file4"

  local head="$(git show -s --format=%H)"
  run git squash -n 3 --empty=abort -m "squash test"

  [ $status -ne 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 6 ]
  [[ $output == *"error: squash ended up in an empty changeset. aborting"* ]] || false
}

@test "git squash with --empty=keep should create an empty commit when squashed commits introduce no change" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file4.txt && git add file4.txt && git commit -m "update file4"
  git rm file4.txt && git commit -m "remove file4"

  local head="$(git show -s --format=%H)"
  run git squash -n 3 --empty=keep -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 4 ]
  [ $(($(git diff HEAD~1..HEAD --name-only | wc -l))) -eq 0 ]
}

@test "git squash with --allow-empty should create an empty commit when squashed commits introduce no change" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file4.txt && git add file4.txt && git commit -m "update file4"
  git rm file4.txt && git commit -m "remove file4"

  local head="$(git show -s --format=%H)"
  run git squash -n 3 --allow-empty -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 4 ]
  [ $(($(git diff HEAD~1..HEAD --name-only | wc -l))) -eq 0 ]
}

@test "git squash <branch-name> should squash all the commits against the given branch" {
  local initial_branch="$(git branch --show-current)"
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  git checkout -b test
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  run git squash "$initial_branch" -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 3 ]
  [ $(($(git diff HEAD~1..HEAD --name-only | wc -l))) -eq 3 ]
  [ "$(git show -s --format=%H "$initial_branch")" == "$(git show -s --format=%H HEAD~1)" ]
}

@test "git squash <tag-name> should squash all the commits against the given tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  git tag v1
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "add file5"

  run git squash v1 -m "squash test"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 3 ]
  [ $(($(git diff HEAD~1..HEAD --name-only | wc -l))) -eq 3 ]
  [ "$(git show -s --format=%H v1)" == "$(git show -s --format=%H HEAD~1)" ]
}

@test "git squash with --verbose should print verbose output" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"

  run git squash -n 2 --verbose -m "squash test"

  [ $status -eq 0 ]
  [[ $output == *"The following commits are squashed:"* ]] || false
  [[ $output == *"into the following commit:"* ]] || false
}

@test "git squash should print verbose output if squash.verbose config is set to true" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"

  git config squash.verbose true
  run git squash -n 2 -m "squash test"

  [ $status -eq 0 ]
  [[ $output == *"The following commits are squashed:"* ]] || false
  [[ $output == *"into the following commit:"* ]] || false
}

@test "git squash with --no-verbose should suppress verbose output even if squash.verbose config is set to true" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "add file3"

  git config squash.verbose true
  run git squash -n 2 -m "squash test" --no-verbose

  [ $status -eq 0 ]
  [[ $output != *"The following commits are squashed:"* ]] || false
  [[ $output != *"into the following commit:"* ]] || false
}
