.PHONY: all
all: clean
	@scripts/generate-dist.sh
	@scripts/generate-install.sh

.PHONY: clean
clean:
	@rm -rf dist/
