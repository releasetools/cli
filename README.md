# Release tools for bash workflows

This toolkit represents a collection of bash scripts for various purposes.

At the time of this writing (2024-10-12) this is WIP.
More utilities are coming as I centralize various scripts from my repositories.

> Any and all contributions are welcome; just open a PR.

## Quickstart

1\. Install the tools

```shell
bash <(curl -sSL "https://github.com/releasetools/bash/releases/download/v0.0.7/install.sh")
```

Or alternatively, with `wget`:

```shell
bash <(wget -q -O- "https://github.com/releasetools/bash/releases/download/v0.0.7/install.sh")
```

The tools will by default be installed to `~/.local/share/releasetools/bash/VERSION/` and a binary will be symlinked at `~/.local/bin/rt`.

2\. Utilize the _releasetools_ library

```shell
# With ~/.local/bin in your PATH:
export PATH=~/.local/bin:"$PATH"

# You can run commands, e.g.:
rt base::::version
# vX.Y.Z

# Optionally, check that all dependencies for all modules are correctly installed
rt base::check_deps
# Ok.

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

The `releasetools/bash` library can be installed via a GitHub workflow:

```yaml
steps:
  ...
  - uses: releasetools/bash@v0
  ...
```

A few customizations are available, if needed:

```yaml
steps:
  # Install releasetools
  - uses: releasetools/bash@v0

  # Customizations
  # with:
  #   # Pin a specific version (defaults to latest)
  #   version: "v0.0.7"
  # env:
  #   # Configure the installation directory
  #   RELEASETOOLS_INSTALL_DIR: /home/runner/.local/share
  #   # Configure where binaries are linked (e.g. a directory that is already in PATH)
  #   RELEASETOOLS_BINARY_DIR: /home/runner/.local/bin

  # Check that `releasetools` was installed correctly
  - run: rt base::check_deps
```

> **NOTE:** Release tools uses `python` for certain actions. When installed as part of a workflow,
> it will attempt to install the [required dependencies](/requirements.txt), if `pip` is available in the `PATH`.

If the workflow also needs python, it is recommended to install it before releasetools, e.g.:

```yaml
steps:
  # Install Python first, to avoid having to install dependencies separately
  - uses: actions/setup-python@v5
    with:
      python-version: "..."

  # Will install releasetools and necessary python dependencies
  - uses: releasetools/bash@v0
```

## Developers

You can find the code and development guidelines in the [src/](./src/) directory.

Once you have completed and tested the code, see the [release instructions](./scripts/#release-a-new-version).

## License

Copyright &copy; 2024 Mihai Bojin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
