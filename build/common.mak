### Common Makefile settings

# Enable secondary expansion
.SECONDEXPANSION:

# Helpers
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

# box dir
BOX_DIR := $(ROOT_DIR)/box

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


# Check whether VirtualBox is installed
ifndef MAKE_VBX
ifneq ($(shell which vboxmanage),)
export MAKE_VBX=1
$(info *** VirtualBox detected ***)
else
export MAKE_VBX=
endif
endif

# Check whether VMware is installed
ifndef MAKE_VMW
ifneq ($(shell which vmrun),)
export MAKE_VMW=1
$(info *** VMware detected ***)
else
export MAKE_VMW=
endif
endif

# Include config settings
include $(ROOT_DIR)/build/config.mak

# Check whether given VM provider ID is valid
define check_valid_vm_provider_id # $1: VM provider ID
	$(if $(filter $1,$(VM_PROVIDER_ID_LIST)),,$(error *** Error: Unkonwn VM provider ID: $1))
endef
