# Release tools for bash workflows

This toolkit represents a collection of bash scripts for various purposes.

At the time of this writing (2024-10-12) this is WIP.
More utilities are coming as I centralize various scripts from my repositories.

> Any and all contributions are welcome; just open a PR.

## Quickstart

1\. Install the tools

```shell
bash <(curl -sSL "https://github.com/releasetools/bash/releases/download/v0.0.5/install.sh")
```

Or alternatively, with `wget`:

```shell
bash <(wget -q -O- "https://github.com/releasetools/bash/releases/download/v0.0.5/install.sh")
```

The tools will by default be installed to `~/.local/share/releasetools/bash/VERSION/` and a binary will be symlinked at `~/.local/bin/rt`.

2\. Utilize the _releasetools_ library

```shell
# With ~/.local/bin in your PATH:
export PATH=~/.local/bin:"$PATH"

# You can run commands, e.g.:
rt base::::version
# vX.Y.Z

# Optionally, check that all dependencies are installed on your system
rt base::check_deps
# Ok.

# Or check individual modules
rt git::internal_check_deps

# You can also check the install location
rt base::install_location
# /Users/user/.local/share/releasetools/bash/vX.Y.Z/releasetools.bash
```

### Customizations

Several customizations can be applied prior to installation:

1\. The location where the tools will be installed:

```shell
export RELEASETOOLS_INSTALL_DIR="$HOME/.local/share"
# proceed with the installation steps outlined above
```

2\. The path where the binary is symlinked:

```shell
export RELEASETOOLS_BINARY_DIR="$HOME/.local/bin"
# proceed with the installation steps outlined above
```

## GitHub Action

The `releasetools/bash` library can be installed via a GitHub workflow,
with the following code:

```yaml
steps:
  # Check out the repository
  - uses: actions/checkout@v4

  # If using the python::* module, install `toml`, e.g.:
  - uses: actions/setup-python@v5
    with:
      python-version: "3.12"
  - run: pip install toml

  # Install releasetools/bash
  - id: releasetools
    uses: releasetools/bash@v0
    with:
      version: "v0.0.5"
    # Customizations
    #env:
    #  # Configure the installation directory
    #  RELEASETOOLS_INSTALL_DIR: /home/runner/.local/share
    #  # Configure where binaries are linked
    #  RELEASETOOLS_BINARY_DIR: /home/runner/.local/bin

  # Check that `rt` was installed correctly
  - run: rt base::version
```

## Developers

You can find the code and development guidelines in the [src/](./src/) directory.

Once you have completed and tested the code, see the [release instructions](./scripts/#release-a-new-version).

## License

Copyright 2024 Mihai Bojin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
