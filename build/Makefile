# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/Makefile.common

.PHONY: all clean get_install_media build package test set_github_vars

# Make all
all:
	@cd $(SRC_DIR) && $(MAKE) all
	@cd $(TEST_DIR) && $(MAKE) all

# Clean (except install media)
clean:
	@cd $(SRC_DIR) && $(MAKE) clean
	@cd $(TEST_DIR) && $(MAKE) clean

# Get install media
get_install_media:
	@cd $(SRC_DIR) && $(MAKE) get_install_media

# Build VM
build:
	@cd $(SRC_DIR) && $(MAKE) build

# Build VM in debug mode
build_debug:
	@cd $(SRC_DIR) && $(MAKE) build_debug

# Package VM
package:
	@cd $(SRC_DIR) && $(MAKE) package

# Test
test:
	@cd $(TEST_DIR) && $(MAKE) test

# Set Github environment variables
set_github_vars:
	@echo "VM_INSTALL_MEDIA_FILE=$(VM_INSTALL_MEDIA_FILE)" >> $$GITHUB_ENV
	@echo "VM_INSTALL_MEDIA_SHA1=$(VM_INSTALL_MEDIA_SHA1)" >> $$GITHUB_ENV

