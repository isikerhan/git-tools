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

if [[ -n "$__LIB_CORE_LOG__" ]]; then
  return
fi
readonly __LIB_CORE_LOG__=true

readonly NO_COLOR="\033[0m"
readonly YELLOW="\033[0;33m"

# print text in specified color
# usage: echo_colored <text> <color_code>
echo_colored() {
  local text="$1"
  local color="$2"
  printf "$color$text$NO_COLOR"$'\n'
}

# print hint
# usage: hint <hint_text>
hint() {
  local text="$1"
  local text_to_print="hint: $text"
  echo_colored "$text_to_print" "$YELLOW"
}
