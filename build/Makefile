# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/common.mak

# Make all
.PHONY: all
all:
	@cd $(BOX_DIR) && $(MAKE) all
	@cd $(TEST_DIR) && $(MAKE) all

# Clean (except install media)
.PHONY: clean
clean:
	@cd $(BOX_DIR) && $(MAKE) clean
	@cd $(TEST_DIR) && $(MAKE) clean

# Get install media
.PHONY: get_install_media
get_install_media:
	@cd $(BOX_DIR) && $(MAKE) get_install_media

# Build VM
.PHONY: build
build:
	@cd $(BOX_DIR) && $(MAKE) build

# Package VM
.PHONY: package
package:
	@cd $(BOX_DIR) && $(MAKE) package

# Test
.PHONY: test
test:
	@cd $(TEST_DIR) && $(MAKE) test

# Set Github environment variables
.PHONY: set_github_vars
set_github_vars:
	@echo "VM_INSTALL_MEDIA_FILE=$(VM_INSTALL_MEDIA_FILE)" >> $$GITHUB_ENV
	@echo "VM_INSTALL_MEDIA_SHA1=$(VM_INSTALL_MEDIA_SHA1)" >> $$GITHUB_ENV

