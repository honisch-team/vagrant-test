# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/common.mak

# src log dir
SRC_LOG_DIR := $(LOG_DIR)/src

# Make all
.PHONY: all
all: get_install_media build package

# Clean all (except install media)
.PHONY: clean
clean: remove_vm dist_clean work_clean

# Get install media
.PHONY: get_install_media
get_install_media:
	@bash $(SRC_DIR)/host/common/get_install_media.sh $(VM_INSTALL_MEDIA_URL) "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_INSTALL_MEDIA_SHA1)

# Build virtual machine
.PHONY: build

# Package virtual machine
.PHONY: package

# Remove virtual machine
.PHONY: remove_vm

# Clean dist folder
.PHONY: dist_clean

# Clean work dir
.PHONY: work_clean

# Include VirtualBox-specific rules
ifeq ($(MAKE_VIRTUALBOX),1)
$(info *** Including VirtualBox build rules ***)
include $(SRC_DIR)/virtualbox.mak
endif

# Include VMware-specific rules
ifeq ($(MAKE_VMWARE),1)
$(info *** Including VMware build rules ***)
include $(SRC_DIR)/vmware.mak
endif
