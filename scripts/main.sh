#!/usr/bin/env bash
#
# main.sh - wrapper script for releasetools/cli
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

set -euo pipefail

# Check if a given string is a valid identifier
function _is_valid_name() {
  local name="${1-}"
  if [[ ! "$name" =~ ^[a-zA-Z0-9_]+$ ]]; then
    return 1
  fi

  return 0
}

# Initialize the list of defined functions
function _init_functions() {
  declare -F | awk '{print $3}' | grep -vE "^_" | while IFS= read -r func; do
    # skip non-namespaced functions
    if [[ ! "$func" == *::* ]]; then
      continue
    fi

    # skip private and incorrectly named namespaces
    namespace="${func%%::*}"
    if [[ "$namespace" == _* ]] || ! _is_valid_name "$namespace"; then
      continue
    fi

    # skip private and incorrectly named functions
    func_name="${func##*::}"
    if [[ "$func_name" == _* ]] || ! _is_valid_name "$func_name"; then
      continue
    fi

    echo "$func"
  done | sort
}

# Initialize the list of known functions
known_functions=()
while IFS='' read -r fn; do known_functions+=("$fn"); done < <(_init_functions)
known_functions+=("version")  # display the 'version'
readonly known_functions

# Lists defined commands from all namespaces
_list_functions() {
  echo
  echo "Available commands:"
  for fn in "${known_functions[@]}"; do
    echo "  - $fn"
  done
}

# This is the main entrypoint.
#
# _main() takes a function name and a list of arguments as input.
# The function name should be in the format of "namespace::function".
# The function should be a valid function.
#
# If the function is not found, it will print an error message and exit.
# If the function is found, it will call the function with any provided arguments.
function _main() {
  # Ensure a function name is provided
  if [ -z "${1-}" ]; then
    echo "ERROR: No function name provided."
    echo "Usage: $(basename "$0") namespace::function [arguments...]"
    _list_functions
    exit 1
  fi

  # Ensure the function name is valid
  if [[ ! "${1-}" =~ ^[a-zA-Z0-9_:]+$ ]]; then
    echo "ERROR: Invalid function name."
    echo "Usage: $(basename "$0") namespace::function [arguments...]"
    _list_functions
    exit 1
  fi

  # Extract the function name and shift the arguments
  local function_name
  function_name="$1"
  shift

  # Check if the function exists
  if ! declare -F "$function_name" >/dev/null; then
    echo "ERROR: Function '$function_name' not found."
    echo "Usage: $(basename "$0") namespace::function [arguments...]"
    _list_functions
    exit 1
  fi

  # Call the function with any provided arguments
  "$function_name" "$@"
}

# Allow printing the version
function version() {
  base::_version
}

# If the script is executed directly, run the specified function
# This enables the script to be both sourced and executed, depending on context
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _main "$@"
else
  # Sourcing the script gives access to the private/internal functions
  # Using this approach is generally not recommended
  echo "Sourced release tools ($(version))..." >&2
fi
