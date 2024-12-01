.PHONY: all
all: clean
	@scripts/generate-dist.sh
	@scripts/generate-install.sh

.PHONY: test
test:
	@echo
	@echo "Testing sources and distributable in the local environment..."
	@shellcheck src/*.bash
	@shellcheck scripts/*.sh
	@bash -c "source dist/releasetools.bash && version && base::check_deps"
	@shellcheck dist/*.sh dist/*.bash

.PHONY: clean
clean:
	@rm -rf dist/
