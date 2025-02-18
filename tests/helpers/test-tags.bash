function has_test_tag() {
  local tag="$1"
  for i in "${!BATS_TEST_TAGS[@]}"; do
    if [[ "${BATS_TEST_TAGS[$i]}" == "$1" ]]; then
      return 0
    fi
  done
  return 1
}
