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

  assert_success
  assert_output
}

# bats test_tags=no-repository
@test "git reapply should fail outside a git repository" {
  run git reapply FEAT-001

  assert_failure
  assert_output --partial "fatal: not a git repository"
}

@test "git reapply should fail when there is a revert in progress" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD --no-commit

  run git reapply FEAT-001

  assert_failure
  assert_output --partial "error: a revert or a cherry-pick sequence in progress"
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

  assert_failure
  assert_output --partial "error: a revert or a cherry-pick sequence in progress"
}

@test "git reapply should fail when there are staged changes" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Hello, again!" >>file5.txt && git add file5.txt

  run git reapply FEAT-001

  assert_failure
  assert_output --partial "error: your local changes would be overwritten by reapply"
}

@test "git reapply should fail when there are unstaged changes" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Hello, again!" >>file5.txt

  run git reapply FEAT-001

  assert_failure
  assert_output --partial "error: your local changes would be overwritten by reapply"
}

@test "git reapply should reapply all the reverted commits prefixed with the given commit log message tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file1.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001 add file1\""
}

@test "git reapply should reapply all the reverted commits prefixed with the given conventional commit message tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "feat(some-stuff) add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "feat(cool-stuff) add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "feat(other-stuff) file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "feat(cool-stuff) add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "feat(yet-another-stuff) add file5"
  git revert HEAD~1 HEAD~2 --no-edit

  run git reapply "feat(cool-stuff)"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 8
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"feat(cool-stuff) add file4\""
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 12
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file2.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"BUGFIX-002 remove file5.txt too\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"BUGFIX-001 remove bad file2.txt to resolve production issue\""
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 12
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file2.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"BUGFIX-002 remove file5.txt too\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"BUGFIX-001 delete bad file2.txt to resolve production issue\""
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 12
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file2.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"BUGFIX-002 remove file5.txt too\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"BUGFIX-001 remove bad file2.txt to resolve production issue\""
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(cat file1.txt | wc -l))) 2
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 14
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^M[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~3..HEAD~2)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"doc: add description to file1\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"chore: add file5\""
  assert_equal "$(git show -s --format=%s HEAD~2)" "Reapply \"fix: add file3\""
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 12
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file2.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"bugfix-002 Remove File5.txt too\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"BUGFIX-001 REMOVE bad file2.txt to resolve production issue\""
}

@test "git reapply with --grep without --extended-regexp should not allow reapplying commits using an extended regex" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "BUGFIX-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "IMPROV-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~4..HEAD --no-edit

  run git reapply --grep "^(FEAT|BUGFIX)"

  assert_failure
  assert_output --partial "error: no matching commits found. nothing to do"
}

@test "git reapply with --grep and --extended-regexp should allow reapplying commits using an extended regex" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "BUGFIX-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "IMPROV-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~4..HEAD --no-edit

  run git reapply --grep "^(FEAT|BUGFIX)" --extended-regexp

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 12
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~3..HEAD~2)" ^A[[:blank:]]*file2.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-003: add file5\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"BUGFIX-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~2)" "Reapply \"FEAT-002 add file2\""
}

@test "git reapply with -s should should reapply all matching commits previously reverted and create a single commit with the message matching the default reapply log message format" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001 -s

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -1)" ^A[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" ^A[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001\""
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -1)" ^A[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" ^A[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "$message"
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

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -1)" ^A[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" ^A[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "$message"
}

@test "git reapply with --no-auto-skip-empty should not skip and stop reapply when a reapply introduces an empty changeset" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~4 --no-edit

  run git reapply FEAT-001 --no-auto-skip-empty

  assert_failure
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file1.txt$
  assert_regex "$(git status -b)" .*"Cherry-pick currently in progress\.".* || assert [ $(git show -s --format=%H CHERRY_PICK_HEAD) ]
}

@test "git reapply with --verbose should print verbose output" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --verbose

  assert_success
  assert_output --partial "The following commits are reapplied:"
  refute_output --partial "The following commits are skipped:"
}

@test "git reapply with --verbose should print verbose output including list of skipped commits" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~4 --no-edit

  run git reapply FEAT-001 --verbose

  assert_success
  assert_output --partial "The following commits are reapplied:"
  assert_output --partial "The following commits are skipped:"
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

  assert_success
  assert_output --partial "The following commits are reapplied:"
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

  assert_success
  refute_output --partial "The following commits are reapplied:"
  refute_output --partial "The following commits are skipped:"
}

@test "git reapply with --author should only reapply matching commits authored by the given author" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3" --author="John Doe <john.doe@example.com>"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4" --author="John Doe <john.doe@example.com>"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --author="John Doe <john.doe@example.com>"

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001: add file3\""
}

@test "git reapply with --committer should only reapply matching commits committed by the given committer" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_NAME="John Doe" GIT_COMMITTER_EMAIL="john.doe@example.com" git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_NAME="John Doe" GIT_COMMITTER_EMAIL="john.doe@example.com" git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --committer="John Doe <john.doe@example.com>"

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001: add file3\""
}

@test "git reapply with --after should only reapply matching commits more recent than the given date" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --after="2020.02.01 00:00:00"

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001: add file3\""
}

@test "git reapply with --before should only reapply matching commits older than the given date" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before="2022.12.31 00:00:00"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file1.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001 add file1\""
}

@test "git reapply with --before --after should only reapply matching commits created between given dates" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before="2022.12.31 00:00:00" --after="2020.02.01 00:00:00"

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001: add file3\""
}

@test "git reapply with --after-commit should only reapply matching commits more recent than the given commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --after-commit=HEAD~7

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001: add file3\""
}

@test "git reapply with --before-commit should only reapply matching commits older than the given commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before-commit=HEAD~5

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file1.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001 add file1\""
}

@test "git reapply with --before-commit --after-commit should only reapply matching commits created between given commits" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~2 HEAD~4 --no-edit

  run git reapply FEAT-001 --before-commit=HEAD~5 --after-commit=HEAD~7

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001: add file3\""
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

  assert_failure
  assert_output --partial "fatal: unreachable revision:"
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

  assert_failure
  assert_output --partial "fatal: unreachable revision:"
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

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 4
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "FEAT-001 add file4"
  assert_equal "$(git show -s --format=%s HEAD~1)" "FEAT-001: add file3"
  assert [ -z "$(git show -s --format=%b)" ]
  assert [ -z "$(git show -s --format=%b HEAD~1)" ]
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

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 4
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file4.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001: add file3\""
  assert_regex "$(git show -s --format=%b)" .*"This reapplies commit $commit1\.".*
  assert_regex "$(git show -s --format=%b HEAD~1)" .*"This reapplies commit $commit2\.".*
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

  assert_success
  assert_equal "$(git show -s --format=%s)" "Reapply \"FEAT-001 add file4\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Reapply \"FEAT-001 add file1\""
  assert_regex "$(git show -s --format=%b)" .*"This reapplies commit $commit1\.".*
  assert_regex "$(git show -s --format=%b HEAD~1)" .*"This reapplies commit $commit2\.".*
}

@test "git reapply with --no-decorate-messages should not include the original commit ids in the commit log messages" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~1 HEAD~3 HEAD~4 --no-edit

  run git reapply FEAT-001 --no-decorate-messages

  assert_success
  assert_equal "$(git show -s --format=%s)" "FEAT-001 add file4"
  assert_equal "$(git show -s --format=%s HEAD~1)" "FEAT-001 add file1"
  assert [ -z "$(git show -s --format=%b)" ]
  assert [ -z "$(git show -s --format=%b HEAD~1)" ]
}
