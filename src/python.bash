#!/usr/bin/env bash
#
# python.bash - Python-related helpers for bash
#
# Copyright (c) 2024 Mihai Bojin, https://MihaiBojin.com/
#
# Licensed under the Apache License, Version 2.0
#   http://www.apache.org/licenses/LICENSE-2.0
#

# Test to ensure that all required utilities are installed.
function python::check_deps() {
    if ! type python >/dev/null 2>&1; then
        echo "python is not installed." >&2
        return 1
    fi

    if ! python -c "import toml" >/dev/null 2>&1; then
        local python
        python="$(command -v python)"
        echo "'toml' is not installed in your python environment ($python)." >&2
        echo "Try 'pip install toml'." >&2
        return 1
    fi
}

# Extracts the project name as configured in 'pyproject.toml'
function python::project_name() {
    local dir
    if [[ -n $1 ]]; then
        dir="$1"
    fi

    # error out if dir is not set
    if [[ -z $dir ]]; then
        echo "You must provide a directory as argument." >&2
        return 1
    fi

    # if pyproject.toml doesn't exist, error out
    if [[ ! -f $dir/pyproject.toml ]]; then
        echo "Directory '$dir' does not contain a 'pyproject.toml'." >&2
        return 1
    fi

    python -c "import toml; print(toml.load('$dir/pyproject.toml')['project']['name'])"
}
