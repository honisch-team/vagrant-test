### Common Makefile settings

# Enable secondary expansion
.SECONDEXPANSION:

# Helpers
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

# src dir
SRC_DIR := $(ROOT_DIR)/src

# test dir
TEST_DIR := $(ROOT_DIR)/test

# log dir
LOG_DIR := $(ROOT_DIR)/log

# install media dir
INSTALL_MEDIA_DIR := $(ROOT_DIR)/install-media

# dist dir
DIST_DIR := $(ROOT_DIR)/dist

# Base dir where VM is created
VM_BASE_DIR := $(abspath $(ROOT_DIR)/vm-base)

# Root dir for Vagrant test environments
VG_TEST_ROOT_DIR := $(ROOT_DIR)/vagrant-test-env

# VM provider IDs
VM_PROVIDER_ID_LIST := vbx vmw

# VM provider names
VM_PROVIDER.vbx := virtualbox
VM_PROVIDER.vmw := vmware


# Check whether VirtualBox is installed
ifndef MAKE_VIRTUALBOX
ifneq ($(shell which vboxmanage),)
export MAKE_VIRTUALBOX=1
$(info *** VirtualBox detected ***)
else
export MAKE_VIRTUALBOX=
endif
endif

# Check whether VMware is installed
ifndef MAKE_VMWARE
ifneq ($(shell which vmrun),)
export MAKE_VMWARE=1
$(info *** VMware detected ***)
else
export MAKE_VMWARE=
endif
endif

# Include config settings
include $(ROOT_DIR)/build/config.mak

# Check whether given VM provider ID is valid
define check_valid_vm_provider_id # $1: VM provider ID
	$(if $(filter $1,$(VM_PROVIDER_ID_LIST)),,$(error *** Error: Unkonwn VM provider ID: $1))
endef
