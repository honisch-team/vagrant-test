# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/Makefile.common

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

ifeq ($(MAKE_VIRTUALBOX),1)
$(info *** Including VirtualBox build rules ***)
# Include VirtualBox-specific rules
include $(SRC_DIR)/Makefile.virtualbox
endif

ifeq ($(MAKE_VMWARE),1)
$(info *** Including VMware build rules ***)
# Include VMware-specific rules
include $(SRC_DIR)/Makefile.vmware
endif
