# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/common.mak

# box log dir
BOX_LOG_DIR := $(LOG_DIR)/box

# Make all
.PHONY: all
all: get_install_media build package

# Clean all (except install media)
.PHONY: clean
clean: remove_vm dist_clean work_clean

# Get install media
.PHONY: get_install_media
get_install_media:
	@bash $(BOX_DIR)/host/common/get_install_media.sh $(VM_INSTALL_MEDIA_URL) "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_INSTALL_MEDIA_SHA1)

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
include $(BOX_DIR)/virtualbox.mak
endif

# Include VMware-specific rules
ifeq ($(MAKE_VMWARE),1)
$(info *** Including VMware build rules ***)
include $(BOX_DIR)/vmware.mak
endif

# Build VM
# %: VM provider ID (vbx, vmw, ...)
build.%: update_vm.% ;

# Create VM
create_vm.%: create_vm_nodeps.% ;

# Install OS in VM
install_os_vm.%: create_vm.% install_os_vm_nodeps.% ;

# Update VM
update_vm.%: install_os_vm.% update_vm_nodeps.% ;

# Package VM
package.%: update_vm.% package_nodeps.% ;

# Create VM (no prerequisites)
# %: VM provider ID (vbx, vmw, ...)
create_vm_nodeps.%: VM_PROVIDER_ID = $*
create_vm_nodeps.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
create_vm_nodeps.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER)"
	$(call check_valid_vm_provider_id,$(VM_PROVIDER_ID))
	@bash $(BOX_DIR)/host/$(VM_PROVIDER)/create_vm_$(VM_PROVIDER_ID).sh $(VM_NAME) $(VM_BASE_DIR)/$(VM_PROVIDER) $(VM_OS_TYPE.$(VM_PROVIDER_ID)) $(VM_CPU_COUNT) $(VM_RAM_MB) $(VM_HDD_SIZE_MB) $(VM_VIDEO_RAM_MB)


# Remove VM from dist
# %: VM provider ID (vbx, vmw, ...)
dist_clean.%: VM_PROVIDER_ID = $*
dist_clean.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
dist_clean.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER)"
	$(call check_valid_vm_provider_id,$(VM_PROVIDER_ID))
	@-rm $(DIST_DIR)/$(VM_PROVIDER)/*
