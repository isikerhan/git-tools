if [ -n "$__LIB_CORE_LOG__" ]; then
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
  printf "$2$text$NO_COLOR"
}

# print hint
# usage: hint <hint_text>
hint() {
  local text="$1"
  local text_to_print="hint: $text"
  echo_colored "$text_to_print" "$YELLOW"
}
