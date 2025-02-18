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
@test "git reapply -h should print help" {
  run git reapply -h

  [ $status -eq 0 ]
  [ -n "$output" ]
}

# bats test_tags=no-repository
@test "git reapply should fail outside a git repository" {
  run git reapply FEAT-001

  [ $status -ne 0 ]
  [[ "$output" == *"fatal: not a git repository"* ]] || false
}

@test "git reapply should fail when there is a revert in progress" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD --no-commit

  run git reapply FEAT-001

  [ $status -ne 0 ]
  [[ "$output" == *"error: a revert or a cherry-pick sequence in progress"* ]] || false
}

@test "git reapply should fail when there is a cherry-pick in progress" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD --no-edit
  git cherry-pick HEAD~2 HEAD~1 || true

  run git reapply FEAT-001

  [ $status -ne 0 ]
  [[ "$output" == *"error: a revert or a cherry-pick sequence in progress"* ]] || false
}

@test "git reapply should fail when there are staged changes" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Hello, again!" >>file5.txt && git add file5.txt

  run git reapply FEAT-001

  [ $status -ne 0 ]
  [[ "$output" == *"error: your local changes would be overwritten by reapply"* ]] || false
}

@test "git reapply should fail when there are unstaged changes" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Hello, again!" >>file5.txt

  run git reapply FEAT-001

  [ $status -ne 0 ]
  [[ "$output" == *"error: your local changes would be overwritten by reapply"* ]] || false
}

@test "git reapply should reapply all the reverted commits prefixed with the given commit log message tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001 add file1\"" ]
}

@test "git reapply should reapply all the reverted commits prefixed with the given conventional commit message tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "feat(some-stuff) add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "feat(cool-stuff) add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "feat(other-stuff) file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "feat(cool-stuff) add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "feat(yet-another-stuff) add file5"
  git revert HEAD~1 HEAD~2 --no-edit

  run git reapply "feat(cool-stuff)"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ ! -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 8 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"feat(cool-stuff) add file4\"" ]
}

@test "git reapply with --grep should reapply all the reverted commits having commit log message matching the given pattern" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  git rm file2.txt && git commit -m "BUGFIX-001 remove bad file2.txt to resolve production issue"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git rm file5.txt && git commit -m "BUGFIX-002 remove file5.txt too"
  git revert HEAD HEAD~2 HEAD~3 --no-edit

  run git reapply --grep="^BUGFIX.*remove.*file[[:digit:]]\.txt.*$"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ ! -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 12 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^D[[:blank:]]*file5.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^D[[:blank:]]*file2.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"BUGFIX-002 remove file5.txt too\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"BUGFIX-001 remove bad file2.txt to resolve production issue\"" ]
}

@test "git reapply with multiple --grep's should reapply all the reverted commits having commit log message matching one of the given patterns" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  git rm file2.txt && git commit -m "BUGFIX-001 delete bad file2.txt to resolve production issue"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git rm file5.txt && git commit -m "BUGFIX-002 remove file5.txt too"
  git revert HEAD HEAD~2 HEAD~3 --no-edit

  run git reapply --grep="^BUGFIX.*remove file[[:digit:]]\.txt.*$" --grep="^BUGFIX.*delete.*file[[:digit:]]\.txt.*$"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ ! -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 12 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^D[[:blank:]]*file5.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^D[[:blank:]]*file2.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"BUGFIX-002 remove file5.txt too\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"BUGFIX-001 delete bad file2.txt to resolve production issue\"" ]
}

@test "git reapply with --grep --all-match with multiple \"--grep\"s should reapply all the reverted commits having commit log message matching all of the given patterns" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  git rm file2.txt && git commit -m "BUGFIX-001 remove bad file2.txt to resolve production issue"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git rm file5.txt && git commit -m "BUGFIX-002 remove file5.txt too"
  git revert HEAD HEAD~2 HEAD~3 --no-edit

  run git reapply --grep="^BUGFIX.*" --grep="remove.*file" --all-match

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ ! -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 12 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^D[[:blank:]]*file5.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^D[[:blank:]]*file2.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"BUGFIX-002 remove file5.txt too\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"BUGFIX-001 remove bad file2.txt to resolve production issue\"" ]
}

@test "git reapply with --grep --invert-grep should reapply all the reverted commits having commit log message not matching the given pattern" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "feat: add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "feat: add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "fix: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "feat: add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "chore: add file5"
  echo "# this file greets the world" >>file1.txt && git add file1.txt && git commit -m "doc: add description to file1"
  git revert HEAD~5..HEAD --no-edit

  run git reapply --grep="^(feat|Revert)" --extended-regexp --invert-grep

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(cat file1.txt | wc -l))) -eq 2 ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 14 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^M[[:blank:]]*file1.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file5.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~3..HEAD~2)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"doc: add description to file1\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"chore: add file5\"" ]
  [ "$(git show -s --format=%s HEAD~2)" == "Reapply \"fix: add file3\"" ]
}

@test "git reapply with --grep -i should reapply all the reverted commits having commit log message matching the given pattern case insensitively" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  git rm file2.txt && git commit -m "BUGFIX-001 REMOVE bad file2.txt to resolve production issue"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git rm file5.txt && git commit -m "bugfix-002 Remove File5.txt too"
  git revert HEAD HEAD~2 HEAD~3 --no-edit

  run git reapply --grep="^BUGFIX.*remove.*file[[:digit:]]\.txt.*$" -i

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ ! -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 12 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^D[[:blank:]]*file5.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^D[[:blank:]]*file2.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"bugfix-002 Remove File5.txt too\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"BUGFIX-001 REMOVE bad file2.txt to resolve production issue\"" ]
}

@test "git reapply with --grep without --extended-regexp should not allow reapplying commits using an extended regex" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "BUGFIX-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "IMPROV-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~4..HEAD --no-edit

  run git reapply --grep "^(FEAT|BUGFIX)"

  [ $status -ne 0 ]
  [[ "$output" == *"error: no matching commits found. nothing to do"* ]] || false
}

@test "git reapply with --grep and --extended-regexp should allow reapplying commits using an extended regex" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "BUGFIX-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "IMPROV-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~4..HEAD --no-edit

  run git reapply --grep "^(FEAT|BUGFIX)" --extended-regexp

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 12 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file5.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~3..HEAD~2)" =~ ^A[[:blank:]]*file2.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-003: add file5\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"BUGFIX-001: add file3\"" ]
  [ "$(git show -s --format=%s HEAD~2)" == "Reapply \"FEAT-002 add file2\"" ]
}

@test "git reapply with -s should should reapply all matching commits previously reverted and create a single commit with the message matching the default reapply log message format" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001 -s

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 9 ]
  [[ "$(git diff --name-status HEAD~1..HEAD | head -1)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001\"" ]
}

@test "git reapply with -sm should should reapply all matching commits previously reverted and create a single commit having the given message as the commit log message" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  local message="This is a test log message!"
  run git reapply FEAT-001 -sm "$message"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 9 ]
  [[ "$(git diff --name-status HEAD~1..HEAD | head -1)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "$message" ]
}

@test "git reapply with -se should should reapply all matching commits previously reverted, create a single commit and ask the user for a commit log message" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  local message="This is a test log message!"
  local config=(-c "core.editor=echo $message >")
  run git "${config[@]}" reapply FEAT-001 -se

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ ! -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 9 ]
  [[ "$(git diff --name-status HEAD~1..HEAD | head -1)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "$message" ]
}

@test "git reapply with --no-auto-skip-empty should not skip and stop reapply when a reapply introduces an empty changeset" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~4 --no-edit

  run git reapply FEAT-001 --no-auto-skip-empty

  [ $status -ne 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 7 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [[ "$(git status -b)" == *"Cherry-pick currently in progress."* || $(git show -s --format=%H CHERRY_PICK_HEAD) ]] || false
}

@test "git reapply with --verbose should print verbose output" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --verbose

  [ $status -eq 0 ]
  [[ "$output" == *"The following commits are reapplied:"* ]] || false
  [[ "$output" != *"The following commits are skipped:"* ]] || false
}

@test "git reapply with --verbose should print verbose output including list of skipped commits" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~4 --no-edit

  run git reapply FEAT-001 --verbose

  [ $status -eq 0 ]
  [[ "$output" == *"The following commits are reapplied:"* ]] || false
  [[ "$output" == *"The following commits are skipped:"* ]] || false
}

@test "git reapply should print verbose output if reapply.verbose config is set to true" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  git config reapply.verbose true
  run git reapply FEAT-001

  [ $status -eq 0 ]
  [[ "$output" == *"The following commits are reapplied:"* ]] || false
}

@test "git reapply with --no-verbose should suppress verbose output even if reapply.verbose config is set to true" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  git config reapply.verbose true
  run git reapply FEAT-001 --no-verbose

  [ $status -eq 0 ]
  [[ "$output" != *"The following commits are reapplied:"* ]] || false
  [[ "$output" != *"The following commits are skipped:"* ]] || false
}

@test "git reapply with --author should only reapply matching commits authored by the given author" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3" --author="John Doe <john.doe@example.com>"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4" --author="John Doe <john.doe@example.com>"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --author="John Doe <john.doe@example.com>"

  [ $status -eq 0 ]
  [ ! -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001: add file3\"" ]
}

@test "git reapply with --committer should only reapply matching commits committed by the given committer" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_NAME="John Doe" GIT_COMMITTER_EMAIL="john.doe@example.com" git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_NAME="John Doe" GIT_COMMITTER_EMAIL="john.doe@example.com" git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --committer="John Doe <john.doe@example.com>"

  [ $status -eq 0 ]
  [ ! -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001: add file3\"" ]
}

@test "git reapply with --after should only reapply matching commits more recent than the given date" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --after="2020.02.01 00:00:00"

  [ $status -eq 0 ]
  [ ! -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001: add file3\"" ]
}

@test "git reapply with --before should only reapply matching commits older than the given date" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before="2022.12.31 00:00:00"

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001: add file3\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001 add file1\"" ]
}

@test "git reapply with --before --after should only reapply matching commits created between given dates" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before="2022.12.31 00:00:00" --after="2020.02.01 00:00:00"

  [ $status -eq 0 ]
  [ ! -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 9 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001: add file3\"" ]
}

@test "git reapply with --after-commit should only reapply matching commits more recent than the given commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --after-commit=HEAD~7

  [ $status -eq 0 ]
  [ ! -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001: add file3\"" ]
}

@test "git reapply with --before-commit should only reapply matching commits older than the given commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before-commit=HEAD~5

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 10 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file1.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001: add file3\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001 add file1\"" ]
}

@test "git reapply with --before-commit --after-commit should only reapply matching commits created between given commits" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before-commit=HEAD~5 --after-commit=HEAD~7

  [ $status -eq 0 ]
  [ ! -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ ! -f file4.txt ]
  [ -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 9 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001: add file3\"" ]
}

@test "git reapply should fail when an unreachable --before-commit is provided" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  git branch test
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  local before_commit="$(git show -s --format=%H HEAD~1)"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit
  git checkout test

  run git reapply FEAT-001 --before-commit="$before_commit"

  [ $status -ne 0 ]
  [[ "$output" == *"fatal: unreachable revision:"* ]] || false
}

@test "git reapply should fail when an unreachable --after-commit is provided" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  git branch test
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  local after_commit="$(git show -s --format=%H HEAD~2)"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit
  git checkout test

  run git reapply FEAT-001 --after-commit="$after_commit"

  [ $status -ne 0 ]
  [[ "$output" == *"fatal: unreachable revision:"* ]] || false
}

@test "git reapply with --source should apply commits reachable from the given revision" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  git checkout -b development
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git checkout -

  run git reapply FEAT-001 --source=development

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ ! -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 4 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "FEAT-001 add file4" ]
  [ "$(git show -s --format=%s HEAD~1)" == "FEAT-001: add file3" ]
  [ -z "$(git show -s --format=%b)" ]
  [ -z "$(git show -s --format=%b HEAD~1)" ]
}

@test "git reapply with --source --decorate-messages should apply commits reachable from the given revision and include the original commit ids in the commit log messages" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  git checkout -b development
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  local commit1="$(git show -s --format=%H HEAD~1)"
  local commit2="$(git show -s --format=%H HEAD~2)"
  git checkout -

  run git reapply FEAT-001 --source=development --decorate-messages

  echo $commit1 $commit2

  [ $status -eq 0 ]
  [ -f file1.txt ]
  [ -f file2.txt ]
  [ -f file3.txt ]
  [ -f file4.txt ]
  [ ! -f file5.txt ]
  [ $(($(git --no-pager log --pretty=oneline | wc -l))) -eq 4 ]
  [[ "$(git diff --name-status HEAD~1..HEAD)" =~ ^A[[:blank:]]*file4.txt$ ]] || false
  [[ "$(git diff --name-status HEAD~2..HEAD~1)" =~ ^A[[:blank:]]*file3.txt$ ]] || false
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001: add file3\"" ]
  [[ "$(git show -s --format=%b)" == *"This reapplies commit $commit1."* ]] || false
  [[ "$(git show -s --format=%b HEAD~1)" == *"This reapplies commit $commit2."* ]] || false
}

@test "git reapply should include the original commit ids in the commit log messages" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  local commit1="$(git show -s --format=%H HEAD~1)"
  local commit2="$(git show -s --format=%H HEAD~4)"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001

  [ $status -eq 0 ]
  [ "$(git show -s --format=%s)" == "Reapply \"FEAT-001 add file4\"" ]
  [ "$(git show -s --format=%s HEAD~1)" == "Reapply \"FEAT-001 add file1\"" ]
  [[ "$(git show -s --format=%b)" == *"This reapplies commit $commit1."* ]] || false
  [[ "$(git show -s --format=%b HEAD~1)" == *"This reapplies commit $commit2."* ]] || false
}

@test "git reapply with --no-decorate-messages should not include the original commit ids in the commit log messages" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001 --no-decorate-messages

  [ $status -eq 0 ]
  [ "$(git show -s --format=%s)" == "FEAT-001 add file4" ]
  [ "$(git show -s --format=%s HEAD~1)" == "FEAT-001 add file1" ]
  [ -z "$(git show -s --format=%b)" ]
  [ -z "$(git show -s --format=%b HEAD~1)" ]
}
