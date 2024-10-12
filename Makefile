.PHONY: all
all: clean
	@scripts/generate-dist.sh
	@scripts/generate-install.sh

.PHONY: test
test:
	@bash -c "source dist/releasetools.bash && releasetools::version"

.PHONY: clean
clean:
	@rm -rf dist/
