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

if [[ -n "$__LIB_GIT_LOG__" ]]; then
  return
fi
readonly __LIB_GIT_LOG__=true
readonly __DIR_LIB_GIT_LOG__=$(dirname -- "${BASH_SOURCE[0]}")

. "$__DIR_LIB_GIT_LOG__/core.bash"
. "$__DIR_LIB_GIT_LOG__/../util/get_options.bash"

# lists git commits
# usage: list_commits [<revision-range>] [--author=me|<pattern>] [--committer=me|<pattern>] [<git-log-options>] [[--] <path>…​]
list_commits() {
  if [[ "$1" == --* ]]; then
    local args_to_parse=("$@")
  elif [[ "$2" == --* ]]; then
    local args_to_parse=("${@:2}")
    local revision_range="$1"
  else
    local args_to_parse=("${@:3}")
    local revision_range="$1 $2"
  fi

  local args=("${args_to_parse[@]}")

  reset_options
  while get_options "" "author:,committer:" opt "${args_to_parse[@]}"; do
    case "$opt" in
    author | committer)
      if [[ "$OPTARG" == "me" ]]; then
        unset args[$OPTIND-2]
        unset args[$OPTIND-3]
        args+=(--$opt "$(get_current_git_user)")
      fi
      ;;
    esac
  done

  git log $revision_range "${args[@]}" --format="%H"
}

# lists git commits by tag
# usage: list_commits <tag> [<revision-range>] [--author=me|<pattern>] [--committer=me|<pattern>] [<git-log-options>] [[--] <path>…​]
list_commits_by_tag() {
  if [[ -z "$1" ]] || [[ "$1" == --* ]]; then
    return 1
  else
    local tag="$1"
    if [[ "$2" == --* ]]; then
      local args_to_parse=("${@:2}")
    elif [[ "$3" == --* ]]; then
      local args_to_parse=("${@:3}")
      local revision_range="$2"
    else
      local args_to_parse=("${@:4}")
      local revision_range="$2 $3"
    fi
  fi

  local args=("${args_to_parse[@]}")

  reset_options
  while get_options "" "grep:" opt "${args_to_parse[@]}"; do
    case "$opt" in
    grep)
      return 2
      ;;
    esac
  done

  local grep="^$tag:\?[^\w()_0-9]"

  list_commits "$revision_range" --grep "$grep" "${args[@]}"
}

# finds the root commit reachable from a specific revision
# usage: find_root_commit [<from_revision>]
find_root_commit() {
  local from_revision="${1:-HEAD}"
  echo "$(git log "$from_revision" --reverse --pretty="%H" | head -1)"
}
