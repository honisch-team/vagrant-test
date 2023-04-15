# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/Makefile.common

# Make all
.PHONY: all
all: get_install_media build package

# Clean (except install media)
.PHONY: clean
clean: remove_vm dist_clean

# Get install media
.PHONY: get_install_media
get_install_media:
	@bash $(SRC_DIR)/host/get_install_media.sh $(VM_INSTALL_MEDIA_URL) "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_INSTALL_MEDIA_SHA1)

# Build virtual machine
.PHONY: build
build: create_vm install_os_vm update_vm

# Create virtual machine
.PHONY: create_vm
create_vm:
	@bash $(SRC_DIR)/host/create_vm.sh $(VM_NAME) $(VM_BASE_DIR) $(VM_OS_TYPE) $(VM_CPU_COUNT) $(VM_RAM_MB) $(VM_HDD_SIZE_MB) $(VM_VIDEO_RAM_MB)

# Install operating system in virtual machine
.PHONY: install_os_vm
install_os_vm:
	@bash $(SRC_DIR)/host/install_os_vm.sh $(VM_NAME) "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update virtual machine after OS install
.PHONY: update_vm
update_vm:
	@bash $(SRC_DIR)/host/update_vm.sh $(VM_NAME) $(VM_USER) $(VM_PASSWORD) $(SRC_DIR)/guest $(UPDATE_VM_OPTS)

# Package virtual machine
.PHONY: package
package:
	@echo "Packaging VM..."
	@vagrant package $(VM_NAME) --base $(VM_NAME) --vagrantfile $(SRC_DIR)/package/Vagrantfile.pkg --output $(DIST_DIR)/$(VM_NAME).box

# Remove virtual machine
.PHONY: PHONY
remove_vm:
	@-bash $(SRC_DIR)/host/remove_vm.sh $(VM_NAME)

# Clean dist
.PHONY: dist_clean
dist_clean:
	@-rm $(DIST_DIR)/*
