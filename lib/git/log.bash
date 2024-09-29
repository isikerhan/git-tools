if [ -n "$__LIB_GIT_LOG__" ]; then
  return
fi
readonly __LIB_GIT_LOG__=true
readonly __DIR_LIB_GIT_LOG__=$(realpath -e -- "$(dirname -- "${BASH_SOURCE[0]}")")

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
        args+=("--$opt $(get_current_git_author)")
      fi
      ;;
    esac
  done

  git log $revision_range ${args[@]} --format="%H"
}

# lists git commits by tag
# usage: list_commits <tag> [<revision-range>] [--conventional] [--author=me|<pattern>] [--committer=me|<pattern>] [<git-log-options>] [[--] <path>…​]
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
  while get_options "" "grep:,conventional" opt "${args_to_parse[@]}"; do
    case "$opt" in
    grep)
      return 2
      ;;
    conventional)
      local conventional=true
      ;;
    esac
  done

  if [[ "$conventional" != "true" ]]; then
    local grep="^$tag\b"
  fi

  list_commits "$revision_range" --grep "$grep" "${args[@]}"
}

# finds initial commit of the current tree and returns its hash
# usage: find_initial_commit
find_initial_commit() {
  echo "$(git log --reverse --pretty="%H" | head -1)"
}
