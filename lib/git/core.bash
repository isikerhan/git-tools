if [ -n "$__LIB_GIT_CORE__" ]; then
  return
fi
readonly __LIB_GIT_CORE__=true
readonly __DIR_LIB_GIT_CORE__=$(dirname -- "${BASH_SOURCE[0]}")

. "$__DIR_LIB_GIT_CORE__/../core/error.bash"

# check if git command is available, fail with a fatal error if not
# usage: check_git_command
check_git_command() {
  git -v >/dev/null 2>&1 || fatal "git not available" "$RET_GIT_NOT_AVAILABLE"
}

# check if the current workdir belongs to a git repository, fail with a fatal error if not
# usage: check_git_repository
check_git_repository() {
  local inside_work_tree=$(git rev-parse --is-inside-work-tree 2>/dev/null)
  if [ ! "$inside_work_tree" == "true" ]; then
    fatal "not a git repository (or any of the parent directories): .git" $RET_GENERIC_ERROR
  fi
}

# get current git author
# usage: get_current_git_author
get_current_git_author() {
  echo "$(git config user.name) <$(git config user.email)>"
}

# get root directory of the current git repository
# usage get_repository_root_dir
get_repository_root_dir() {
  git rev-parse --show-toplevel
}

# get git directory of the current git repository
# usage get_git_dir
get_git_dir() {
  local rootdir=$(get_repository_root_dir)
  echo "$rootdir/.git"
}

# check if current git repository has staged changes. returns 0 if so, non-zero otherwise
# usage: has_staged_changes
has_staged_changes() {
  git diff --cached --exit-code >/dev/null 2>&1
  local ret=$?
  ! [ $ret -eq 0 ]
}
# check if current git repository has unstaged changes. returns 0 if so, non-zero otherwise
# usage: has_unstaged_changes
has_unstaged_changes() {
  git diff --exit-code >/dev/null 2>&1
  local ret=$?
  ! [ $ret -eq 0 ]
}

# check if current git repository has a sequencer. this indicates that there's an ongoing revert or cherry-pick
# usage: has_sequencer
has_sequencer() {
  local gitdir="$(get_git_dir)"
  [ -d "$gitdir/sequencer" ]
}

# get next todo item from the sequencer
# usage: get_next_todo
get_next_todo() {
  if ! has_sequencer; then
    return
  fi

  local gitdir="$(get_git_dir)"
  echo "$(head -n 1 "$gitdir/sequencer/todo")"
}
