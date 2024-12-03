#!/usr/bin/env bash
#
# git.bash - git-related helpers for bash
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function github::_internal_check_deps() {
    return 0
}

# Determines if the current git reference is a version tag.
# Returns the semantic version prefixed with 'v' if the reference is a tag,
# or exits with an error message.
# 
# Usage: github::get_version [--env]
#       --env: appends VERSION=v#.#.# to the file specified by the GITHUB_ENV environment variable
function github::get_version() {
  local store_to_github_env
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --env)
        store_to_github_env=true
        shift
        ;;
      *)
        echo "Unknown parameter passed: $1" >&2
        exit 1
        ;;
      esac
  done

  # Determine if the GITHUB_REF environment variable is set
  local ref
  ref="${GITHUB_REF-}"

  # If the reference is empty, attempt to get it from git
  if [ -z "$ref" ]; then
    # Attempt to get the reference from git
    GIT_REF="$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)"

    # If found, populate the ref variable similarly to GITHUB_REF
    if [ -n "$GIT_REF" ]; then
      ref="refs/${GIT_REF%%\^0}"
    fi
  fi

  # Stop, if the reference is empty
  if [[ -z "$ref" ]]; then
    echo "GITHUB_REF is not set and could not be retrieved via git either" >&2
    exit 1
  fi

  if [[ "$ref" =~ refs/tags/(v[0-9]+(\.[0-9]+){0,2})$ ]]; then
    # Attempt to extract the match
    VERSION="${BASH_REMATCH[1]}"
    if [ -z "$VERSION" ]; then
      # If not found, also try zsh's match array
      # (this is to support sourcing the script in zsh)
      # shellcheck disable=SC2154
      VERSION="${match[1]}"
    fi

    echo "Found version: $VERSION" >&2
    if [ "$store_to_github_env" = true ]; then
      if [ -z "${GITHUB_ENV-}" ]; then
        echo "GITHUB_ENV is not set. Cannot continue." >&2
        exit 1
      fi
      echo "VERSION=$VERSION" >> "$GITHUB_ENV"
    fi
    echo "$VERSION"
  else
    echo "No matching version found" >&2
    exit 1
  fi
}
