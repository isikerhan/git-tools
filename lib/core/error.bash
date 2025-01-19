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

if [[ -n "$__LIB_CORE_ERROR__" ]]; then
  return
fi
readonly __LIB_CORE_ERROR__=true

# predefined error codes
readonly RET_GENERIC_ERROR=128
readonly RET_GIT_NOT_AVAILABLE=2
readonly RET_ILLEGAL_OPTION=129

# error severity levels
readonly SEVERITY_ERROR="error"
readonly SEVERITY_FATAL="fatal"

# report a failure and exit
# usage: fail severity message exit_code
# *intended for internal usage within this file
function fail() {
  local level="$1"
  local message="$2"
  local exit_code="$3"

  if [[ -z "$exit_code" ]]; then
    exit_code=1
  fi

  printf "$level: $message"'\n' >&2

  if [[ $exit_code -ne 0 ]]; then
    exit "$exit_code"
  fi
}

# report an error and exit
# usage: error message exit_code
function error() {
  local message="$1"
  local exit_code="$2"

  fail "$SEVERITY_ERROR" "$message" "$exit_code"
}

# report an error and exit
# usage: error message exit_code
function fatal() {
  local message="$1"
  local exit_code="$2"

  fail "$SEVERITY_FATAL" "$message" "$exit_code"
}

# get option type name: "option" or "switch"
# usage: get_option_type_name opt_name
# *intended for internal usage within this file
function get_option_type_name() {
  local opt="$1"

  if [[ ${#opt} -gt 1 ]]; then
    echo "option"
  else
    echo "switch"
  fi
}

# report missing option value error and exit
# usage: error_missing_opt_value opt_name
function error_missing_opt_value() {
  local opt="$1"

  error "$(get_option_type_name $opt) \`$opt' requires a value" "$RET_ILLEGAL_OPTION"
}

# report missing option value error and exit
# usage: error_unknown_opt opt_name
function error_unknown_opt() {
  local opt="$1"
  local usage="$2"

  local message="unknown $(get_option_type_name $opt) \`$opt'"

  if [[ -n "$usage" ]]; then
    message+='\n'
    message+="$usage"
  fi

  error "$message" "$RET_ILLEGAL_OPTION"
}
