_common_setup_file() {
  GIT_TOOLS_PATH="$(realpath "$BATS_TEST_DIRNAME/..")"

  if [[ ! "$PATH" == *"$GIT_TOOLS_PATH"* ]]; then
    export PATH="$GIT_TOOLS_PATH:$PATH"
  fi

  export OLD_PWD="$PWD"
  cd "$BATS_FILE_TMPDIR"
}

_common_teardown_file() {
  cd "$OLD_PWD"
  unset OLD_PWD
}

_common_setup() {
  export BATS_LIB_PATH=${BATS_LIB_PATH:-"/usr/lib"}
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  load "helpers/test-tags.bash"

  if ! has_test_tag "no-repository"; then
    GIT_REPOSITORY_DIR="$BATS_TEST_TMPDIR/repo"
    mkdir "$GIT_REPOSITORY_DIR" && cd "$GIT_REPOSITORY_DIR" && git init
    export GIT_REPOSITORY_DIR
  else
    cd "$BATS_TEST_TMPDIR"
  fi
}

_common_teardown() {
  unset GIT_REPOSITORY_DIR
  cd "$BATS_FILE_TMPDIR"
}
