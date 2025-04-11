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

if [[ -n "$__LIB_GIT_CONFIG__" ]]; then
  return
fi
readonly __LIB_GIT_CONFIG__=true

# get git config (or default)
# usage: get_git_config <config_key> [<default_value>]
get_git_config() {
  local config_key="$1"
  local default_value="$2"

  local value="$(git config "$config_key" 2>/dev/null)"
  echo "${value:${default_value}}"
}
