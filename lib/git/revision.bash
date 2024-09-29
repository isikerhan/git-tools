if [ -n "$__LIB_GIT_REVISION__" ]; then
  return
fi
readonly __LIB_GIT_REVISION__=true
readonly __DIR_LIB_GIT_REVISION__=$(realpath -e -- "$(dirname -- "${BASH_SOURCE[0]}")")

# echoes the commit hash of the speficied revision
# usage: resolve_revision <revision>
resolve_revision() {
  echo "$(git show -s --pretty="%H" "$1" 2>/dev/null)"
}

# checks if revision exists, returns 0 if so, otherwise non-zero
# usage: check_revision <revision>
check_revision() {
  git show -s --pretty="%H" "$1" >/dev/null 2>&1
}
