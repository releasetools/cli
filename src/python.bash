#!/usr/bin/env bash
#
# python.bash - Python-related helpers for bash
#
# Copyright (c) 2025 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function python::_internal_check_deps() {
    if ! type python >/dev/null 2>&1; then
        echo "python is not installed." >&2
        return 1
    fi

    if ! python -c "import toml" >/dev/null 2>&1; then
        echo "'toml' is not installed in your python environment ($(command -v python))." >&2
        echo "Try 'pip install toml'." >&2
        return 1
    fi
}

# Extracts the project name as configured in 'pyproject.toml'
function python::project_name() {
    # Defaulted: the library runs under 'set -u', so a bare "$1" made calling this with no
    # arguments die on an unbound variable instead of printing the message below.
    local dir="${1-}"

    # error out if dir is not set
    if [[ ! -d "$dir" ]]; then
        echo "You must provide a directory as argument." >&2
        return 1
    fi

    # if pyproject.toml doesn't exist, error out
    if [[ ! -f "$dir/pyproject.toml" ]]; then
        echo "Directory '$dir' does not contain a 'pyproject.toml'." >&2
        return 1
    fi

    # The path is passed as an argument rather than interpolated into the source, so a
    # directory containing a quote character cannot break or inject into the snippet.
    python -c "import sys, toml; print(toml.load(sys.argv[1])['project']['name'])" \
        "$dir/pyproject.toml"
}
