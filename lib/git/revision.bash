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

if [[ -n "$__LIB_GIT_REVISION__" ]]; then
  return
fi
readonly __LIB_GIT_REVISION__=true

# echoes the commit hash (or the commit in specified <pretty> format) of the speficied revision
# usage: resolve_revision <revision> [<pretty>]
resolve_revision() {
  local revision="$1"
  local pretty="${2:-%H}"

  echo "$(git show -s --pretty="$pretty" "$revision" 2>/dev/null)"
}

# checks if revision exists, returns 0 if so, otherwise non-zero
# usage: revision_exists <revision>
revision_exists() {
  local revision="$1"

  git show -s --pretty="%H" "$revision" >/dev/null 2>&1
}

# returns number of commits between two revisions in current tree
# usage: num_commits_between <from> <to>
num_commits_between() {
  local from="$1"
  local to="$2"

  git rev-list --count "$to" "$from" 2>/dev/null
}

# returns commit hashes between two revisions in current tree
# usage: commits_between <from> <to>
commits_between() {
  local from="$1"
  local to="$2"

  git rev-list "$to" "$from" 2>/dev/null
}
