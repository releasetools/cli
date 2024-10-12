# Release tools for bash workflows

This toolkit represents a collection of bash scripts for various purposes.

At the time of this writing (2024-10-12) this is WIP.
More utilities are coming as I centralize various scripts from my repositories.

> Any and all contributions are welcome; just open a PR.

## Quickstart

1\. Install the tools

```shell
bash <(curl -sSL "https://github.com/releasetools/bash/releases/download/v0.0.3/install.sh")
```

Or alternatively, with `wget`:

```shell
bash <(wget -q -O- "https://github.com/releasetools/bash/releases/download/v0.0.3/install.sh")
```

The composed module will be downloaded to `~/.local/bin/releasetools/bash/v0.0.3/releasetools.bash`.

2\. Source the toolkit

```shell
. ~/.local/bin/releasetools/bash/v0.0.3/releasetools.bash

# optionally, check that all dependencies are installed
git::check_deps
python::check_deps
```

You can now use the provided tools.

## Developers

You can find the code and development guidelines in the [src/](./src/) directory.

Once you have completed and tested the code, see the [release instructions](./scripts/#releasing-a-new-version).

## License

Copyright 2024 Mihai Bojin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
