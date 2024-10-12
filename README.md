# Release tools for bash workflows

This toolkit represents a collection of bash scripts for various purposes.

At the time of this writing (2024-10-12) this is WIP; more utilities are coming
as I centralize various scripts from my repositories.

> Any and all contributions are welcome; just open a PR.

## Quickstart

Source the following modules in your shell, to avoid building similar logic in your repositories.

```shell
source <(curl -sSL "https://raw.githubusercontent.com/releasetools/bash/refs/heads/main/src/git.bash")
source <(curl -sSL "https://raw.githubusercontent.com/releasetools/bash/refs/heads/main/src/python.bash")

# Optionally, check that the module was sourced and all dependencies are available in your environment
git::check_deps
python::check_deps
```

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
