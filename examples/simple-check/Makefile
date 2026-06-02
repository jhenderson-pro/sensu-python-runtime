NAME := simple-disk-check
VERSION ?= 0.1.0
DIST_DIR := dist
TARBALL := $(DIST_DIR)/$(NAME)_$(VERSION)_linux_amd64.tar.gz

.PHONY: package clean

package:
	mkdir -p $(DIST_DIR)
	tar -czf $(TARBALL) bin libexec README.md
	shasum -a 512 $(TARBALL) > $(TARBALL).sha512

clean:
	rm -rf $(DIST_DIR)
