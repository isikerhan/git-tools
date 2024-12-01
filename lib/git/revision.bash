if [ -n "$__LIB_GIT_REVISION__" ]; then
  return
fi
readonly __LIB_GIT_REVISION__=true

# echoes the commit hash of the speficied revision
# usage: resolve_revision <revision>
resolve_revision() {
  echo "$(git show -s --pretty="%H" "$1" 2>/dev/null)"
}

# checks if revision exists, returns 0 if so, otherwise non-zero
# usage: revision_exists <revision>
revision_exists() {
  git show -s --pretty="%H" "$1" >/dev/null 2>&1
}

# returns number of commits between two revisions in current tree
# usage: num_commits_between <from> <to>
num_commits_between() {
  local from="$1"
  local to="$2"

  git rev-list --count $2 $1 2>/dev/null
}

# returns commit hashes between two revisions in current tree
# usage: commits_between <from> <to>
commits_between() {
  local from="$1"
  local to="$2"

  git rev-list $2 $1 2>/dev/null
}
