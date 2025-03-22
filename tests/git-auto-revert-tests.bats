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
@test "git auto-revert -h should print help" {
  run git auto-revert -h

  assert_success
  assert_output
}

# bats test_tags=no-repository
@test "git auto-revert should fail outside a git repository" {
  run git auto-revert FEAT-001

  assert_failure
  assert_output --partial "fatal: not a git repository"
}

@test "git auto-revert should fail when there is a revert in progress" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD --no-commit

  run git auto-revert FEAT-001

  assert_failure
  assert_output --partial "error: a revert or a cherry-pick sequence in progress"
}

@test "git auto-revert should fail when there is a cherry-pick in progress" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD --no-edit
  git cherry-pick HEAD~2 HEAD~1 || true

  run git auto-revert FEAT-001

  assert_failure
  assert_output --partial "error: a revert or a cherry-pick sequence in progress"
}

@test "git auto-revert should fail when there are staged changes" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Hello, again!" >>file5.txt && git add file5.txt

  run git auto-revert FEAT-001

  assert_failure
  assert_output --partial "error: your local changes would be overwritten by auto-revert"
}

@test "git auto-revert should fail when there are unstaged changes" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Hello, again!" >>file5.txt

  run git auto-revert FEAT-001

  assert_failure
  assert_output --partial "error: your local changes would be overwritten by auto-revert"
}

@test "git auto-revert should revert all commits prefixed with the given commit log message tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 8
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~3..HEAD~2)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001 add file1\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~2)" "Revert \"FEAT-001 add file4\""
}

@test "git auto-revert should revert all commits prefixed with the given conventional commit message tag" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "feat(some-stuff) add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "feat(cool-stuff) add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "feat(other-stuff) file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "feat(cool-stuff) add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "feat(yet-another-stuff) add file5"

  run git auto-revert "feat(cool-stuff)"

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file2.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"feat(cool-stuff) add file2\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"feat(cool-stuff) add file4\""
}

@test "git auto-revert with --grep should revert all commits having commit log message matching the given pattern" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  git rm file2.txt && git commit -m "BUGFIX-001 remove bad file2.txt to resolve production issue"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git rm file5.txt && git commit -m "BUGFIX-002 remove file5.txt too"

  run git auto-revert --grep="^.*remove.*file[[:digit:]]\.txt.*$"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^A[[:blank:]]*file2.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^A[[:blank:]]*file5.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"BUGFIX-001 remove bad file2.txt to resolve production issue\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"BUGFIX-002 remove file5.txt too\""
}

@test "git auto-revert with multiple --grep's should revert all commits having commit log message matching one of the given patterns" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hey!" >>"file1.txt" && git add file1.txt && git commit -m "BUGFIX-001: modify content of file1.txt"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Yo!" >>"file4.txt" && git add file4.txt && git commit -m "BUGFIX-002 edit file4.txt"

  run git auto-revert --grep="^.*modify.*file[[:digit:]]\.txt.*$" --grep="^.*edit.*file[[:digit:]]\.txt.*$"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(cat file1.txt | wc -l))) 1
  assert_equal $(($(cat file4.txt | wc -l))) 1
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^M[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^M[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"BUGFIX-001: modify content of file1.txt\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"BUGFIX-002 edit file4.txt\""
}

@test "git auto-revert with --grep --all-match with multiple \"--grep\"s should revert all commits having commit log message matching all of the given patterns" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hey!" >>"file1.txt" && git add file1.txt && git commit -m "BUGFIX-001: edit content of file1.txt"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  echo "Yo!" >>"file4.txt" && git add file4.txt && git commit -m "BUGFIX-002 edit file4.txt"
  echo "Whoops!" >>"file5.txt" && git add file5.txt && git commit -m "FEAT-003 edit file5.txt"

  run git auto-revert --grep="^BUGFIX" --grep="edit" --all-match

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(cat file1.txt | wc -l))) 1
  assert_equal $(($(cat file4.txt | wc -l))) 1
  assert_equal $(($(cat file5.txt | wc -l))) 2
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 10
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^M[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^M[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"BUGFIX-001: edit content of file1.txt\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"BUGFIX-002 edit file4.txt\""
}

@test "git auto-revert with --grep --invert-grep should revert all commits having commit log message not matching the given pattern" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "feat: add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "feat: add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "fix: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "feat: add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "chore: add file5"
  echo "# this file greets the world" >>file1.txt && git add file1.txt && git commit -m "doc: add description to file1"

  run git auto-revert --grep="^feat" --invert-grep

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_exists file4.txt
  assert_file_not_exists file5.txt
  assert_equal $(($(cat file1.txt | wc -l))) 1
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 9
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file5.txt$
  assert_regex "$(git diff --name-status HEAD~3..HEAD~2)" ^M[[:blank:]]*file1.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"fix: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"chore: add file5\""
  assert_equal "$(git show -s --format=%s HEAD~2)" "Revert \"doc: add description to file1\""
}

@test "git auto-revert with --grep -i should revert all commits having commit log message matching the given pattern case insensitively" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "feat: add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "fix: create file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "feat: file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FIX add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "feat: add file5"

  run git auto-revert --grep="^fix" -i

  assert_success
  assert_file_exists file1.txt
  assert_file_not_exists file2.txt
  assert_file_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file2.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"fix: create file2\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FIX add file4\""
}

@test "git auto-revert with --grep without --extended-regexp should not allow reverting commits using an extended regex" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "BUGFIX-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "IMPROV-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert --grep "^(FEAT|BUGFIX)"

  assert_failure
  assert_output --partial "error: no matching commits found. nothing to do"
}

@test "git auto-revert with --grep and --extended-regexp should allow reverting commits using an extended regex" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "BUGFIX-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "IMPROV-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert --grep "^(IMPROV|BUGFIX)" --extended-regexp

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"BUGFIX-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"IMPROV-001 add file4\""
}

@test "git auto-revert with -s should should revert all matching commits and create a single commit with the message matching the default revert log message format" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 -s

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 6
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -1)" ^D[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | tail -1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001\""
}

@test "git auto-revert with -sm should should revert all matching commits and create a single commit having the given message as the commit log message" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  local message="This is a test log message!"
  run git auto-revert FEAT-001 -sm "$message"

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 6
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -1)" ^D[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | tail -1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "$message"
}

@test "git auto-revert with -se should should revert all matching commits, create a single commit and ask the user for a commit log message" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  local message="This is a test log message!"
  local config=(-c "core.editor=echo $message >")
  run git "${config[@]}" auto-revert FEAT-001 -se

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 6
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -1)" ^D[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | head -2 | tail -1)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~1..HEAD | tail -1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "$message"
}

@test "git auto-revert with --no-auto-skip-empty should not skip and stop auto-revert when a revert introduces an empty commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~2 --no-edit

  run git auto-revert FEAT-001 --no-auto-skip-empty

  assert_failure
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file4.txt$
  assert_regex "$(git status -b)" .*"Revert currently in progress\.".* || assert [ $(git show -s --format=%H REVERT_HEAD) ]
}

@test "git auto-revert with --verbose should print verbose output" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --verbose

  assert_success
  assert_output --partial "The following commits are reverted:"
  refute_output --partial "The following commits are skipped:"
}

@test "git auto-revert with --verbose should print verbose output including list of skipped commits" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  git revert HEAD~2 --no-edit

  run git auto-revert FEAT-001 --verbose

  assert_success
  assert_output --partial "The following commits are reverted:"
  assert_output --partial "The following commits are skipped:"
}

@test "git auto-revert should print verbose output if autoRevert.verbose config is set to true" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  git config autoRevert.verbose true
  run git auto-revert FEAT-001

  assert_success
  assert_output --partial "The following commits are reverted:"
}

@test "git auto-revert with --no-verbose should suppress verbose output even if autoRevert.verbose config is set to true" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  git config autoRevert.verbose true
  run git auto-revert FEAT-001 --no-verbose

  assert_success
  refute_output --partial "The following commits are reverted:"
  refute_output --partial "The following commits are skipped:"
}

@test "git auto-revert with --author should only revert matching commits authored by the given author" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3" --author="John Doe <john.doe@example.com>"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4" --author="John Doe <john.doe@example.com>"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --author="John Doe <john.doe@example.com>"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001 add file4\""
}

@test "git auto-revert with --committer should only revert matching commits committed by the given committer" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_NAME="John Doe" GIT_COMMITTER_EMAIL="john.doe@example.com" git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_NAME="John Doe" GIT_COMMITTER_EMAIL="john.doe@example.com" git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --committer="John Doe <john.doe@example.com>"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001 add file4\""
}

@test "git auto-revert with --after should only revert matching commits more recent than the given date" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --after="2020.02.01 00:00:00"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001 add file4\""
}

@test "git auto-revert with --before should only revert matching commits older than the given date" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --before="2022.12.31 00:00:00"

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001 add file1\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001: add file3\""
}

@test "git auto-revert with --before --after should only revert matching commits created between given dates" {
  echo "Hello, World!" >file1.txt && git add file1.txt && GIT_COMMITTER_DATE="2020.01.01 00:00:00" git commit --date="2020.01.01 00:00:00" -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && GIT_COMMITTER_DATE="2021.01.01 00:00:00" git commit --date="2021.01.01 00:00:00" -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && GIT_COMMITTER_DATE="2022.01.01 00:00:00" git commit --date="2022.01.01 00:00:00" -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && GIT_COMMITTER_DATE="2023.01.01 00:00:00" git commit --date="2023.01.01 00:00:00" -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && GIT_COMMITTER_DATE="2024.01.01 00:00:00" git commit --date="2024.01.01 00:00:00" -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --before="2022.12.31 00:00:00" --after="2020.02.01 00:00:00"

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 6
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001: add file3\""
}

@test "git auto-revert with --after-commit should only revert matching commits more recent than the given commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --after-commit=HEAD~4

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_not_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file4.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001: add file3\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001 add file4\""
}

@test "git auto-revert with --before-commit should only revert matching commits older than the given commit" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --before-commit=HEAD~2

  assert_success
  assert_file_not_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 7
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file1.txt$
  assert_regex "$(git diff --name-status HEAD~2..HEAD~1)" ^D[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001 add file1\""
  assert_equal "$(git show -s --format=%s HEAD~1)" "Revert \"FEAT-001: add file3\""
}

@test "git auto-revert with --before-commit --after-commit should only revert matching commits created between given commits" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"

  run git auto-revert FEAT-001 --before-commit=HEAD~2 --after-commit=HEAD~4

  assert_success
  assert_file_exists file1.txt
  assert_file_exists file2.txt
  assert_file_not_exists file3.txt
  assert_file_exists file4.txt
  assert_file_exists file5.txt
  assert_equal $(($(git --no-pager log --pretty=oneline | wc -l))) 6
  assert_regex "$(git diff --name-status HEAD~1..HEAD)" ^D[[:blank:]]*file3.txt$
  assert_equal "$(git show -s --format=%s)" "Revert \"FEAT-001: add file3\""
}

@test "git auto-revert should fail when an unreachable --before-commit is provided" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  git branch test
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  local before_commit="$(git show -s --format=%H HEAD~1)"

  git checkout test
  run git auto-revert FEAT-001 --before-commit="$before_commit"

  assert_failure
  assert_output --partial "fatal: unreachable revision:"
}
@test "git auto-revert should fail when an unreachable --after-commit is provided" {
  echo "Hello, World!" >file1.txt && git add file1.txt && git commit -m "FEAT-001 add file1"
  echo "Hello, Mercury!" >file2.txt && git add file2.txt && git commit -m "FEAT-002 add file2"
  git branch test
  echo "Hello, Venus!" >file3.txt && git add file3.txt && git commit -m "FEAT-001: add file3"
  echo "Hello, Mars!" >file4.txt && git add file4.txt && git commit -m "FEAT-001 add file4"
  echo "Hello, Jupiter!" >file5.txt && git add file5.txt && git commit -m "FEAT-003: add file5"
  local after_commit="$(git show -s --format=%H HEAD~2)"

  git checkout test
  run git auto-revert FEAT-001 --after-commit="$after_commit"

  assert_failure
  assert_output --partial "fatal: unreachable revision:"
}
