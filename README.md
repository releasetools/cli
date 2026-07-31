# Release tools for bash workflows

This toolkit represents a collection of bash scripts for various purposes.

> Any and all contributions are welcome; just open a PR.

## Quickstart

1\. Install the tools

```shell
# curl
bash <(curl -sSL "https://github.com/releasetools/cli/releases/latest/download/install.sh")

# or wget
bash <(wget -q -O- "https://github.com/releasetools/cli/releases/latest/download/install.sh")
```

> These URLs always resolve to the most recent release. To install a specific version,
> replace `latest/download` with `download/vX.Y.Z`.

Or alternatively, with `brew`:

```shell
brew tap releasetools/tap
brew install releasetools-cli
```

The tools will by default be installed to `~/.local/share/releasetools/cli/VERSION/` and a binary will be symlinked at `~/.local/bin/releasetools`.

2\. Utilize the _releasetools_ library

```shell
# With ~/.local/bin in your PATH:
export PATH=~/.local/bin:"$PATH"

# You can run commands, e.g.:
releasetools version
# vX.Y.Z

# Optionally, check that all dependencies for all modules are correctly installed
releasetools base::check_deps
# Ok.

# You can also check the install location
releasetools base::install_location
# /Users/user/.local/share/releasetools/cli/vX.Y.Z/releasetools.bash
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

The `releasetools/cli` library can be installed via a GitHub workflow:

```yaml
steps:
  ...
  - uses: releasetools/cli@v0
  ...
```

A few customizations are available, if needed:

```yaml
steps:
  # Install releasetools
  - uses: releasetools/cli@v0

  # Customizations
  # with:
  #   # Pin a specific version (defaults to the version this action was released with)
  #   version: "vX.Y.Z"
  # env:
  #   # Configure the installation directory
  #   RELEASETOOLS_INSTALL_DIR: /home/runner/.local/share
  #   # Configure where binaries are linked (e.g. a directory that is already in PATH)
  #   RELEASETOOLS_BINARY_DIR: /home/runner/.local/bin

  # Check that `releasetools` was installed correctly
  - run: releasetools base::check_deps
```

> **NOTE:** there is nothing to install alongside it. Every module is bash over `git`,
> `gh` and coreutils, so the action is a single download-and-link step.

## Developers

You can find the code and development guidelines in the [src/](./src/) directory.

Once you have completed and tested the code, see the [release instructions](./scripts/#release-a-new-version).

## License

Copyright &copy; 2025 Mihai Bojin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
