if [ -n "$__LIB_GIT_TAG__" ]; then
  return
fi
readonly __LIB_GIT_TAG__=true
readonly __DIR_LIB_GIT_TAG__=$(dirname -- "${BASH_SOURCE[0]}")

# checks if tag exists, returns 0 if so, otherwise non-zero
# usage: check_tag <tag>
check_tag() {
  git tag | grep "$1" >/dev/null 2>&1
}
