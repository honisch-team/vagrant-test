# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/Makefile.common

.PHONY: all clean get_install_media build create_vm install_os_vm update_vm package remove_vm dist_clean

# Make all
all: get_install_media build package

# Clean (except install media)
clean: remove_vm dist_clean

# Get install media
get_install_media:
	@bash $(SRC_DIR)/host/get_install_media.sh $(VM_INSTALL_MEDIA_URL) "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_INSTALL_MEDIA_SHA1)

# Build virtual machine
build: create_vm install_os_vm update_vm

# Create virtual machine
create_vm:
	@bash $(SRC_DIR)/host/create_vm.sh $(VM_NAME) $(VM_BASE_DIR) $(VM_OS_TYPE) $(VM_CPU_COUNT) $(VM_RAM_MB) $(VM_HDD_SIZE_MB) $(VM_VIDEO_RAM_MB)

# Install operating system in virtual machine
install_os_vm:
	@bash $(SRC_DIR)/host/install_os_vm.sh $(VM_NAME) "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update virtual machine after OS install
update_vm:
	@bash $(SRC_DIR)/host/update_vm.sh $(VM_NAME) $(VM_USER) $(VM_PASSWORD) $(SRC_DIR)/guest

# Package virtual machine
package:
	@echo "Packaging VM..."
	@vagrant package $(VM_NAME) --base $(VM_NAME) --vagrantfile $(SRC_DIR)/package/Vagrantfile.pkg --output $(DIST_DIR)/$(VM_NAME).box

# Remove virtual machine
remove_vm:
	@-bash $(SRC_DIR)/host/remove_vm.sh $(VM_NAME)

# Clean dist
dist_clean:
	@-rm $(DIST_DIR)/*
