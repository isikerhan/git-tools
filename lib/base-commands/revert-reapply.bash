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

if [[ -n "$__LIB_BASE_COMMANDS_REVERT_REAPPLY__" ]]; then
  return
fi
readonly __LIB_BASE_COMMANDS_REVERT_REAPPLY__=true
readonly __DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__=$(dirname -- "${BASH_SOURCE[0]}")

. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../core/error.bash"
. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../core/log.bash"
. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../git/config.bash"
. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../git/core.bash"
. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../git/log.bash"
. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../git/revision.bash"
. "$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../util/get_options.bash"

readonly ACTION_AUTO_REVERT="AUTO_REVERT"
readonly ACTION_REAPPLY="REAPPLY"

readonly REAPPLY_HOOKS_PATH="$__DIR_LIB_BASE_COMMANDS_REVERT_REAPPLY__/../hooks/reapply"

readonly VERBOSE_CONFIG_KEY="verbose"
readonly VERBOSE_CONFIG_DEFAULT_VALUE="false"

# check for the prerequisites for auto-revert/reapply
# usage: check_prerequisites
# *intended for internal usage within this file
check_prerequisites() {
  check_git_command
}

# check for the status of respoitory for auto-revert/reapply
# usage: check_repository_status
# *intended for internal usage within this file
check_repository_status() {
  check_git_repository
  check_ongoing_revert_or_cherry_pick "$action_name"
  check_uncommitted_changes "$action_name"
}

# print auto-revert/reapply options
# usage: print_options
# *intended for internal usage within this file
print_options() {
  echo

  if [[ "$revert_reapply_action" == "$ACTION_REAPPLY" ]]; then
    echo "    --source              source revision that commits are searched from
    --[no-]decorate-messages
                          add decoration to auto-generated commit messages to indicate they are reapplied"
  fi

  echo "    -s, --single-commit   apply all the changes within a single commit
    -m, --message         commit message for the single commit. ignored if --single-commit is not enabled
    -n, --no-commit       don't automatically commit
    --commit              opposite of --no-commit
    -e, --[no-]edit       edit the commit message
    --[no-]auto-skip-empty
                          automatically skip commits which introduce no change
    -v, --[no-]verbose    be verbose
    --grep=<pattern>      limit the commits selected to ones with a log message that match the specified pattern. required if commit message tag is not specified
    --author=<pattern>    author of the commits to be selected. set to \"me\" for the current user
    --committer=<pattern> committer of the commits to be selected. set to \"me\" for the current user
    --since=<date>, --after=<date>
                          limit commits selected to the ones that are more recent than a specific date
    --until=<date>, --before=<date>       
                          limit commits selected to the ones that are older than a specific date
    --since-commit=<commit>, --after-commit=<commit>
                          limit commits selected to the ones that are more recent than the specified revision (excluding specified revision)
    --until-commit=<commit>, --before-commit=<commit>
                          limit commits selected to the ones that are older than the specified revision (including specified revision)

Options related to limiting patterns (ignored if no pattern is specified with --grep=<pattern>)
    --all-match           limit the commits selected to ones that match all given --grep, instead of ones that match at least one
    --invert-grep         limit the commits selected to ones with a log message that do not match the pattern specified with --grep=<pattern>
    -i, --regexp-ignore-case 
                          match the regular expression limiting patterns without regard to letter case
    --basic-regexp        consider the limiting patterns to be basic regular expressions; this is the default
    -E, --extended-regexp consider the limiting patterns to be extended regular expressions instead of the default basic regular expressions
    -F, --fixed-strings   consider the limiting patterns to be fixed strings (don't interpret pattern as a regular expression)
    -P, --perl-regex      consider the limiting patterns to be Perl-compatible regular expressions
"
}

# print auto-revert usage
# usage: print_auto_revert_usage
# *intended for internal usage within this file
print_auto_revert_usage() {
  echo "usage: git auto-revert <commit-message-tag> [<options>]
   or: git auto-revert --grep=<pattern> [<options>]"
}

# print reapply usage
# usage: print_reapply_usage
# *intended for internal usage within this file
print_reapply_usage() {
  echo "usage: git reapply <commit-message-tag> [<options>]
   or: git reapply --grep=<pattern> [<options>]"
}

# print auto-revert/reapply usage
# usage: print_usage
# *intended for internal usage within this file
print_usage() {
  if [[ "$revert_reapply_action" == "$ACTION_AUTO_REVERT" ]]; then
    print_auto_revert_usage
  else
    print_reapply_usage
  fi

  print_options
}

# validate auto-revert/reapply options
# usage: validate_options
# *intended for internal usage within this file
validate_options() {
  if [[ -n "$tag" ]] && [[ "${#grep[@]}" -gt 0 ]]; then
    error "<commit-message-tag> cannot be used with --grep" $RET_ILLEGAL_OPTION
  fi

  if [[ -z "$tag" ]] && [[ "${#grep[@]}" -eq 0 ]]; then
    error "either a <commit-message-tag> or --grep must be specified" $RET_ILLEGAL_OPTION
  fi

  local tag_regex=^[\(\)a-zA-Z0-9_-]+$
  if [[ -n "$tag" ]] && [[ ! $tag =~ $tag_regex ]]; then
    error "<commit-message-tag> must consist of only letters, digits, hypens, underscores and parentheses" $RET_ILLEGAL_OPTION
  fi

  if [[ "$single_commit" == "true" ]] && [[ -z "$single_commit_message" ]] && [[ -z "$tag" ]]; then
    error "--message is required when reverting in a single commit and <commit-message-tag> is not specified" $RET_ILLEGAL_OPTION
  fi

  if [[ "$single_commit" == "true" ]] && [[ "$no_commit" == "true" ]]; then
    error "--single-commit cannot be used with --no-commit" $RET_ILLEGAL_OPTION
  fi
}

# parse auto-revert/reapply options
# usage: parse_options
# *intended for internal usage within this file
parse_options() {
  grep=()
  single_commit=false
  no_commit=false
  edit=false
  verbose=false
  auto_skip_empty=true
  all_match=false
  invert_grep=false
  regexp_ignore_case=false
  basic_regexp=false
  extended_regexp=false
  fixed_strings=false
  perl_regexp=false

  local verbose_config="$(get_git_config "$git_config_prefix.$VERBOSE_CONFIG_KEY" "$VERBOSE_CONFIG_DEFAULT_VALUE")"

  if [[ "$verbose_config" == "true" ]]; then
    verbose=true
  fi

  if [[ ! "$1" == -* ]]; then
    OPTIND=2
    tag="$1"
  else
    OPTIND=1
  fi

  local long_opts="help,single-commit,message:,no-commit,commit,edit,no-edit,auto-skip-empty,no-auto-skip-empty,verbose,no-verbose,grep:,author:,committer:"
  long_opts+=",since:,after:,until:,before:,since-commit:,after-commit:,until-commit:,before-commit:"
  long_opts+=",all-match,invert-grep,regexp-ignore-case,basic-regexp,extended-regexp,fixed-strings,perl-regexp"
  local optstring="hsm:neviEFP"

  if [[ "$revert_reapply_action" == "$ACTION_REAPPLY" ]]; then
    long_opts+=",source,decorate-messages,no-decorate-messages"
  fi

  while get_options "$optstring" "$long_opts" opt "$@"; do
    case "$opt" in
    h | help)
      print_usage
      exit 0
      ;;
    source)
      source="$OPTARG"
      ;;
    decorate-messages)
      decorate_messages=true
      ;;
    no-decorate-messages)
      decorate_messages=false
      ;;
    s | single-commit)
      single_commit=true
      ;;
    m | message)
      single_commit_message="$OPTARG"
      ;;
    n | no-commit)
      no_commit=true
      ;;
    commit)
      no_commit=false
      ;;
    e | edit)
      edit=true
      ;;
    no-edit)
      edit=false
      ;;
    auto-skip-empty)
      auto_skip_empty=true
      ;;
    no-auto-skip-empty)
      auto_skip_empty=false
      ;;
    v | verbose)
      verbose=true
      ;;
    no-verbose)
      verbose=false
      ;;
    grep)
      grep+=("$OPTARG")
      ;;
    all-match)
      all_match=true
      ;;
    invert-grep)
      invert_grep=true
      ;;
    i | regexp-ignore-case)
      regexp_ignore_case=true
      ;;
    basic-regexp)
      basic_regexp=true
      ;;
    E | extended-regexp)
      extended_regexp=true
      ;;
    F | fixed-strings)
      fixed_strings=true
      ;;
    P | perl-regexp)
      perl_regexp=true
      ;;
    author)
      author="$OPTARG"
      ;;
    committer)
      committer="$OPTARG"
      ;;
    since | after)
      since="$OPTARG"
      ;;
    until | before)
      until="$OPTARG"
      ;;
    since-commit | after-commit)
      since_commit="$OPTARG"
      ;;
    until-commit | before-commit)
      until_commit="$OPTARG"
      ;;
    :)
      error_missing_opt_value "$OPTARG"
      ;;
    *)
      error_unknown_opt "$OPTARG" "$(print_usage)"
      ;;
    esac
  done

  validate_options
}

# find commits for revert/reapply operation
# usage: find_commits
# *intended for internal usage within this file
find_commits() {
  local source_revision=HEAD

  if [[ -n "$source" ]]; then
    source_revision="$source"
  fi

  local revision_range
  local first_parent=false

  if [[ -n "$since_commit" ]]; then
    revision_exists "$since_commit" || error "unknown revision: $since_commit"
    is_revision_reachable "$since_commit" "$source_revision" || fatal "unreachable revision: $since_commit" $RET_GENERIC_ERROR
    local rev_start="$since_commit"
  fi

  if [[ -n "$until_commit" ]]; then
    revision_exists "$until_commit" || error "unknown revision: $until_commit"
    is_revision_reachable "$until_commit" "$source_revision" || fatal "unreachable revision: $until_commit" $RET_GENERIC_ERROR
    local rev_end="$until_commit"
  fi

  if [[ -n "$rev_start" ]] || [[ -n "$rev_end" ]]; then
    if [[ -z "$rev_start" ]]; then
      revision_range="$rev_end"
      first_parent=true
    else
      revision_range="$rev_start..$rev_end"
    fi
  fi

  if [[ -n "$source_revision" ]] && [[ -z "$revision_range" ]]; then
    revision_range="$source_revision"
  fi

  local find_commits_opts=(--no-merges)

  if [[ "$revert_reapply_action" == "$ACTION_REAPPLY" ]]; then
    find_commits_opts+=(--reverse)
  fi

  if [[ ${#grep[@]} -gt 0 ]]; then
    for grep_val in "${grep[@]}"; do
      find_commits_opts+=(--grep "$grep_val")
    done

    if [[ "$all_match" == "true" ]]; then
      find_commits_opts+=(--all-match)
    fi

    if [[ "$invert_grep" == "true" ]]; then
      find_commits_opts+=(--invert-grep)
    fi

    if [[ "$regexp_ignore_case" == "true" ]]; then
      find_commits_opts+=(--regexp-ignore-case)
    fi

    if [[ "$basic_regexp" == "true" ]]; then
      find_commits_opts+=(--basic-regexp)
    fi

    if [[ "$extended_regexp" == "true" ]]; then
      find_commits_opts+=(--extended-regexp)
    fi

    if [[ "$fixed_strings" == "true" ]]; then
      find_commits_opts+=(--fixed-strings)
    fi

    if [[ "$perl_regexp" == "true" ]]; then
      find_commits_opts+=(--perl-regexp)
    fi
  fi

  if [[ "$first_parent" == "true" ]]; then
    find_commits_opts+=(--first-parent)
  fi

  if [[ -n "$author" ]]; then
    find_commits_opts+=(--author "$author")
  fi

  if [[ -n "$committer" ]]; then
    find_commits_opts+=(--committer "$committer")
  fi

  if [[ -n "$since" ]]; then
    find_commits_opts+=(--since "$since")
  fi

  if [[ -n "$until" ]]; then
    find_commits_opts+=(--until "$until")
  fi

  if [[ -z "$tag" ]]; then
    commit_hashes=($(list_commits "$revision_range" "${find_commits_opts[@]}"))
  else
    commit_hashes=($(list_commits_by_tag "$tag" "$revision_range" "${find_commits_opts[@]}"))
  fi
}

# build commit message for the auto-revert/reapply operation
# usage: build_commit_message
# *intended for internal usage within this file
build_commit_message() {
  local commit_message

  if [[ -n "$single_commit_message" ]]; then
    commit_message="$single_commit_message"
  else
    if [[ "$revert_reapply_action" == "$ACTION_AUTO_REVERT" ]]; then
      commit_message="Revert \"$tag\""
    else
      commit_message="Reapply \"$tag\""
    fi
  fi

  commit_message+=$'\n\n'

  for commit in "${commit_hashes[@]}"; do
    if is_skipped "$commit"; then
      continue
    fi

    if [[ "$revert_reapply_action" == "$ACTION_AUTO_REVERT" ]]; then
      commit_message+="This reverts commit $commit."$'\n'
    else
      commit_message+="This reapplies commit $commit."$'\n'
    fi
  done

  printf "$commit_message"
}

# check if current revert/cherry-pick operation is skippable
# usage: is_skippable
# *intended for internal usage within this file
is_skippable() {
  local next_todo=$(get_next_todo)
  [[ "$todo" != "$next_todo" ]] && has_sequencer && ! has_staged_changes && ! has_unstaged_changes
}

# check if given commit is skipped during auto-revert/reapply
# usage: is_skipped <commit_hash>
# *intended for internal usage within this file
is_skipped() {
  local commit="$1"

  for skipped_commit in "${skipped_commit_hashes[@]}"; do
    if [[ "$skipped_commit" == "$commit" ]]; then
      true
      return
    fi
  done

  false
}

# create commit for auto-revert/reapply operation
# usage: commit
# *intended for internal usage within this file
commit() {
  local message=$(build_commit_message)
  local commit_opts=()

  if [[ "$edit" == "true" ]]; then
    commit_opts+=(--edit)
  else
    commit_opts+=(--no-edit)
  fi

  local temp_output temp_output_pid
  create_temp_output 1 temp_output temp_output_pid

  local editor="$(redirected_git_editor "$temp_output")"
  local git_config=(-c "color.advice=always" -c "core.editor=$editor")

  git "${git_config[@]}" commit -m "$message" "${commit_opts[@]}" >/dev/null
  local commit_result=$?

  close_temp_output $temp_output $temp_output_pid

  if [[ $commit_result -ne 0 ]]; then
    exit $command_result
  fi
}

# squash commits after given base commit
# usage: squash_commits <base_commit>
# *intended for internal usage within this file
squash_commits() {
  local base_commit="$1"
  git reset $base_commit --soft
  commit
}

# print given commits in a human readable format
# usage: print_commits <commits>
# *intended for internal usage within this file
print_commits() {
  local commits=$@

  for commit in ${commits[@]}; do
    git log -n 1 "$commit" --format="%C(auto)[%h] (%an <%ae>): %s"
  done
}

# whether or not to decorate commit messages
# usage: should_decorate_messages
# *intended for internal usage within this file
should_decorate_messages() {
  [[ "$decorate_messages" == "true" ]] || ([[ -z "$source" ]] && [[ "$decorate_messages" != "false" ]])
}

# perform revert/reapply operation
# usage: do_revert_reapply <action>
# *intended for internal usage within this file
do_revert_reapply() {
  if [[ -z "$commit_hashes" ]]; then
    error "no matching commits found. nothing to do" $RET_GENERIC_ERROR
  fi

  local base_commit=$(resolve_revision HEAD)

  local command_opts=()

  if [[ "$no_commit" == "true" ]]; then
    command_opts+=(--no-commit)
  fi

  if [[ "$edit" == "true" ]] && [[ "$single_commit" != "true" ]]; then
    command_opts+=(--edit)
  else
    command_opts+=(--no-edit)
  fi

  local temp_output
  local temp_output_pid
  create_temp_output 1 temp_output temp_output_pid

  local editor="$(redirected_git_editor "$temp_output")"

  local command_err
  local command_result
  local git_config=(-c "color.advice=always" -c "core.editor=$editor")

  if [[ "$revert_reapply_action" == "$ACTION_REAPPLY" ]] && should_decorate_messages; then
    git_config+=(-c "core.hooksPath=$REAPPLY_HOOKS_PATH")
  fi

  command_err="$(git "${git_config[@]}" $git_command_name "${command_opts[@]}" ${commit_hashes[*]} 2>&1 >/dev/null)"
  command_result=$?

  skipped_commit_hashes=()

  if [[ $command_result -ne 0 ]] && [[ "$auto_skip_empty" == "true" ]]; then
    while [[ $command_result -ne 0 ]] && is_skippable; do
      todo=$(get_next_todo)

      command_err="$(git "${git_config[@]}" $git_command_name --skip "${command_opts[@]}" 2>&1 >/dev/null)"
      command_result=$?

      local todo_parts
      IFS=' ' read -r -a todo_parts <<<"$todo"
      skipped_commit_hashes+=($(resolve_revision ${todo_parts[1]}))
    done
  fi

  close_temp_output $temp_output $temp_output_pid

  local numdone=$((${#commit_hashes[@]} - ${#skipped_commit_hashes[@]}))

  if [[ $numdone -eq 0 ]] || ([[ ${#commit_hashes[@]} -eq 1 ]] && [[ -z "$command_err" ]] && [[ $command_result -ne 0 ]]); then
    if [[ "$verbose" == "true" ]]; then
      echo "The following commits are skipped:"
      print_commits ${commit_hashes[@]}
      echo
    fi

    echo "All matched commits are skipped. Nothing to $action_name_short"
  elif [[ $command_result -eq 0 ]]; then
    if [[ "$single_commit" == "true" ]]; then
      squash_commits "$base_commit"
    fi

    if [[ "$verbose" == "true" ]]; then
      local done_commit_hashes=()
      for commit in ${commit_hashes[@]}; do
        if ! is_skipped "$commit"; then
          done_commit_hashes+=("$commit")
        fi
      done

      echo "The following commits are $action_name_past:"
      print_commits ${done_commit_hashes[@]}
      echo

      if [[ ${#skipped_commit_hashes[@]} -gt 0 ]]; then
        echo "The following commits are skipped:"
        print_commits ${skipped_commit_hashes[@]}
        echo
      fi
    fi

    printf "Successfully $action_name_past $numdone commit(s)"
    if [[ ${#skipped_commit_hashes[@]} -ne 0 ]]; then
      printf " (skipped ${#skipped_commit_hashes[@]})"
    fi
    echo ""

    if [[ "$no_commit" == "true" ]]; then
      local gitdir="$(get_git_dir)"
      echo "$(build_commit_message)" >"$gitdir/MERGE_MSG"

      hint "changes are not committed"
      hint "use \"git $git_command_name --continue\" or \"git commit\" to commit the changes"
    fi
  else
    if [[ -n "$command_err" ]]; then
      printf "${command_err%'\n'}\n\n" >&2
    fi
    error "unable to $action_name" 0
    if has_unresolved_conflicts; then
      hint "fix the conflicts and continue the $git_command_name operation manually" >&2
      hint "or use \"git $git_command_name --abort\" to cancel the $action_name operation" >&2
    fi
    fatal "$action_name failed" $RET_GENERIC_ERROR
  fi
}

# bulk revert or reapply commits based on set of filters
# usage revert_reapply <action> <options>
revert_reapply() {
  revert_reapply_action="$1"
  local options=("${@:2}")

  if [[ "$revert_reapply_action" != "$ACTION_AUTO_REVERT" ]] && [[ "$revert_reapply_action" != "$ACTION_REAPPLY" ]]; then
    fatal "invalid action: $revert_reapply_action" $RET_GENERIC_ERROR
  fi

  if [[ "$revert_reapply_action" == "$ACTION_AUTO_REVERT" ]]; then
    git_command_name="revert"
    git_config_prefix="autoRevert"
    action_name="auto-revert"
    action_name_short="revert"
    action_name_past="reverted"
  else
    git_command_name="cherry-pick"
    git_config_prefix="reapply"
    action_name="reapply"
    action_name_short="reapply"
    action_name_past="reapplied"
  fi

  check_prerequisites
  parse_options "${options[@]}"
  check_repository_status

  find_commits
  do_revert_reapply
}
