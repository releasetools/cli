#!/usr/bin/env bash
#
# github.bash - GitHub-related helpers for bash
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
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
# or returns non-zero with an error message.
#
# Usage: github::get_version [--env]
#       --env: appends VERSION=v#.#.# to the file specified by the GITHUB_ENV environment variable
function github::get_version() {
  # Must be initialized: it is tested below, and the library runs under 'set -u',
  # so leaving it unassigned made the function fail unless '--env' was passed.
  local store_to_github_env=false
  local ref
  local git_ref
  local version

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --env)
      store_to_github_env=true
      shift
      ;;
    *)
      echo "Unknown parameter passed: $1" >&2
      return 1
      ;;
    esac
  done

  # Determine if the GITHUB_REF environment variable is set
  ref="${GITHUB_REF-}"

  # If the reference is empty, attempt to get it from git
  if [ -z "$ref" ]; then
    # Attempt to get the reference from git
    # '|| true' keeps a non-git directory from failing the assignment: as a bare
    # command substitution under 'set -e' that aborted the caller, making the
    # "could not be retrieved via git either" message below unreachable.
    git_ref="$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD || true)"

    # If found, populate the ref variable similarly to GITHUB_REF
    if [ -n "$git_ref" ]; then
      ref="refs/${git_ref%%\^0}"
    fi
  fi

  # Stop, if the reference is empty
  if [[ -z "$ref" ]]; then
    echo "GITHUB_REF is not set and could not be retrieved via git either" >&2
    return 1
  fi

  if [[ "$ref" =~ refs/tags/(v[0-9]+(\.[0-9]+){0,2})$ ]]; then
    # The regex above only validates the shape; the value is taken with parameter expansion
    # because bash and zsh expose capture groups incompatibly. bash fills BASH_REMATCH, zsh
    # fills 'match' -- except under 'setopt BASH_REMATCH', where zsh fills BASH_REMATCH with
    # the *whole* match instead of the group, so reading it there yielded
    # 'refs/tags/v1.2.3' as the version. Stripping the prefix is correct in every shell.
    version="${ref##*refs/tags/}"

    echo "Found version: $version" >&2
    if [ "$store_to_github_env" = true ]; then
      if [ -z "${GITHUB_ENV-}" ]; then
        echo "GITHUB_ENV is not set. Cannot continue." >&2
        return 1
      fi
      echo "VERSION=$version" >>"$GITHUB_ENV"
    fi
    echo "$version"
  else
    echo "No matching version found" >&2
    return 1
  fi
}
