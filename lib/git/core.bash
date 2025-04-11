# Git Tools. A set of custom Git commands that might come in handy for certain tasks.
#
# Copyright (C) 2025 Isik Erhan
#
# This file is part of Git Tools.
#
# Git Tools is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Git Tools is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Git Tools.  If not, see <https://www.gnu.org/licenses/>.

if [ -n "$__LIB_GIT_CORE__" ]; then
  return
fi
readonly __LIB_GIT_CORE__=true
readonly __DIR_LIB_GIT_CORE__=$(dirname -- "${BASH_SOURCE[0]}")

. "$__DIR_LIB_GIT_CORE__/config.bash"
. "$__DIR_LIB_GIT_CORE__/revision.bash"
. "$__DIR_LIB_GIT_CORE__/../core/error.bash"
. "$__DIR_LIB_GIT_CORE__/../core/os.bash"

# check if git command is available, fail with a fatal error if not
# usage: check_git_command
check_git_command() {
  command -v git >/dev/null 2>&1 || fatal "git not available" "$RET_GIT_NOT_AVAILABLE"
}

# check if the current workdir belongs to a git repository, fail with a fatal error if not
# usage: check_git_repository
check_git_repository() {
  local inside_work_tree=$(git rev-parse --is-inside-work-tree 2>/dev/null)
  if [ ! "$inside_work_tree" == "true" ]; then
    fatal "not a git repository (or any of the parent directories): .git" $RET_GENERIC_ERROR
  fi
}

# check if current git repository has onging revert or cherry-pick sequence
# usage: has_ongoing_revert_or_cherry_pick
has_ongoing_revert_or_cherry_pick() {
  has_sequencer || revision_exists REVERT_HEAD || revision_exists CHERRY_PICK_HEAD
}

# check if current git repository has onging revert or cherry-pick sequence, fail with a fatal error if so
# usage: check_ongoing_revert_or_cherry_pick <action_name> [<retcode>]
check_ongoing_revert_or_cherry_pick() {
  local action_name="$1"
  local retcode=$2

  if [ -z "$retcode" ]; then
    retcode=$RET_GENERIC_ERROR
  fi

  if has_ongoing_revert_or_cherry_pick; then
    error "a revert or a cherry-pick sequence in progress" 0
    hint "complete or abort revert/cherry-pick sequence first to proceed." >&2
    fatal "$action_name failed" $retcode
  fi
}

# check if current git repository has any uncommitted tracked changes
# usage has_uncommitted_changes
has_uncommitted_changes() {
  has_staged_changes || has_unstaged_changes
}

# check if current git repository has any uncommitted tracked changes, fail with a fatal error if so
# usage check_uncommitted_changes <action_name> [<retcode>]
check_uncommitted_changes() {
  local action_name="$1"
  local retcode=$2

  if [ -z "$retcode" ]; then
    retcode=$RET_GENERIC_ERROR
  fi

  if has_uncommitted_changes; then
    error "your local changes would be overwritten by $action_name." 0
    hint "commit your changes or stash them to proceed." >&2
    fatal "$action_name failed" $RET_GENERIC_ERROR
  fi
}

# check if current git repository has onging rebase
# usage: has_ongoing_rebase
has_ongoing_rebase() {
  revision_exists REBASE_HEAD
}

# check if current git repository has onging rebase, fail with a fatal error if so
# usage: check_ongoing_rebase <action_name> [<retcode>]
check_ongoing_rebase() {
  local action_name="$1"
  local retcode=$2

  if [ -z "$retcode" ]; then
    retcode=$RET_GENERIC_ERROR
  fi

  if has_ongoing_rebase; then
    error "rebase in progress" 0
    hint "complete or abort the rebase first to proceed." >&2
    fatal "$action_name failed" $retcode
  fi
}

# get current git author
# usage: get_current_git_user
get_current_git_user() {
  echo "$(get_git_config user.name) <$(get_git_config user.email)>"
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

# check if current git repository has unresolved conflicts. returns 0 if so, non-zero otherwise
# usage: has_unresolved_conflicts
has_unresolved_conflicts() {
  [ -n "$(git diff --name-only --diff-filter=U --relative 2>/dev/null)" ]
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

readonly DEFAULT_GIT_EDITOR=vi

# find editor used by git
# usage find_git_editor
find_git_editor() {
  local config_editor="$(get_git_config core.editor)"

  if [[ -n "$config_editor" ]]; then
    echo "$config_editor"
    return
  fi

  if [[ -n "$GIT_EDITOR" ]]; then
    echo "$GIT_EDITOR"
    return
  fi

  if [[ -n "$VISUAL" ]]; then
    echo "$VISUAL"
    return
  fi

  if [[ -n "$EDITOR" ]]; then
    echo "$EDITOR"
    return
  fi

  echo "$DEFAULT_GIT_EDITOR"
}

# return current editor command with its stdout redirected to the given target
# usage redirected_git_editor stdout_target
redirected_git_editor() {
  local stdout_target="$1"

  local editor="$(find_git_editor)"

  if is_open_fd "$stdout_target"; then
    echo "bash -c \">&$stdout_target $editor \$1\""
  else
    echo "bash -c \">$stdout_target $editor \$1\""
  fi
}

# check if a given revision is reachable from HEAD
# usage: is_revision_reachable <revision> [<from_revision>]
is_revision_reachable() {
  local revision="$1"
  local from_revision="${2:-HEAD}"
  git merge-base --is-ancestor "$revision" "$from_revision" >/dev/null 2>&1
}
