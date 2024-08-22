if [ -n "$__LIB_UTIL_GET_OPTIONS__" ]; then
  return
fi
readonly __LIB_UTIL_GET_OPTIONS__=true

# parse command line arguments and get options, supporting long options
# usage: get_options optstring long_opts name [args]
function get_options {
  local opt_string="$1"
  local long_opts="$2"
  local opt_param="$3"
  local optarr=("${@:4}")

  function find_long_option {
    local long_options="$1"
    local option_name="$2"

    for curr_opt in ${long_options//,/ }; do
      if [[ "$curr_opt" =~ ^"$option_name":?$ ]]; then
        echo "$curr_opt"
        break
      fi
    done
  }

  function parse_long_option {
    local value

    if [[ "$OPTARG" =~ ^(.+)=(.+)$ ]]; then
      value="${BASH_REMATCH[2]}"
      OPTARG="${BASH_REMATCH[1]}"
    elif [[ ! "${@:$OPTIND:1}" =~ ^-.+$ ]]; then
      value="${@:$OPTIND:1}"
      OPTIND=$OPTIND+1
    fi

    opt_config=$(find_long_option "$long_opts" "$OPTARG")

    if [[ -z "$opt_config" ]]; then
      eval "$opt_param=?"
    elif [ "$opt_config" == "$OPTARG:" ] && [ -z "$value" ]; then
      eval "$opt_param=:"
    else
      opt="$OPTARG"
      OPTARG="$value"
    fi
  }

  local opt_string_suffix=""
  local opt_string_prefix=""

  if [ ! -z "$long_opts" ]; then
    opt_string_suffix="-:"
  fi

  if [ ! "${opt_string[0]}" == ":" ]; then
    opt_string_prefix=":"
  fi

  if [ "$OPTIND" -gt "${#optarr[@]}" ]; then
    return 1
  fi

  getopts "$opt_string_prefix$opt_string$opt_string_suffix" "$opt_param" "${optarr[@]}"

  if [ "${!opt_param}" = "-" ]; then
    parse_long_option "${optarr[@]}"
  fi
}
