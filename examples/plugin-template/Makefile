NAME ?= my-python-check
VERSION ?= 0.1.0
DIST_DIR := dist
TARBALL := $(DIST_DIR)/$(NAME)_$(VERSION)_linux_amd64.tar.gz
PYTHON ?= python3

.PHONY: vendor package clean

vendor:
	mkdir -p lib
	if command -v uv >/dev/null 2>&1; then \
		uv pip install --target lib -r requirements.txt; \
	else \
		$(PYTHON) -m pip install --target lib -r requirements.txt; \
	fi

package: vendor
	mkdir -p $(DIST_DIR)
	tar -czf $(TARBALL) bin lib libexec README.md requirements.txt
	shasum -a 512 $(TARBALL) > $(TARBALL).sha512

clean:
	rm -rf $(DIST_DIR) lib
