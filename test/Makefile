# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/common.mak

# Vagrant text box name prefix
VG_TEST_BOX_NAME := test-box

# Test data dir
TEST_DATA_DIR := $(TEST_DIR)/host/data

# Test guest resources dir
TEST_RES_DIR := $(TEST_DIR)/guest

# Test log dir
TEST_LOG_DIR := $(LOG_DIR)/test

# Test run IDs
TESTRUN_ID_LIST := default clockoffset

# VM provider IDs
VM_PROVIDER_ID_LIST := vbx vmw

# Make all
.PHONY: all
all: test

# Clean
.PHONY: clean

# Test
.PHONY: test

ifeq ($(MAKE_VIRTUALBOX),1)
$(info *** Including VirtualBox test rules ***)
# Include VirtualBox-specific rules
include $(TEST_DIR)/virtualbox.mak
endif

ifeq ($(MAKE_VMWARE),1)
$(info *** Including VMware test rules ***)
# Include VMware-specific rules
include $(TEST_DIR)/vmware.mak
endif

# Exec test for given VM provider
# %: VM provider ID (vbx, vmw, ...)
test.%: install_box.% $$(addprefix testrun.%.,$(TESTRUN_ID_LIST)) ;

# Clean for given VM provider
# %: VM provider ID (vbx, vmw, ...)
clean.%: $$(addprefix clean_testrun.%.,$(TESTRUN_ID_LIST)) remove_box.% ;

# Clean for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
clean_testrun.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
clean_testrun.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
clean_testrun.%: destroy_box.% clean_test_logs.% ;

# Clean test logs for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
clean_test_logs.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
clean_test_logs.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
clean_test_logs.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
clean_test_logs.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), test run ID: $(TESTRUN_ID)"
	@-rm -rf "$(TEST_LOG_DIR)/vagrant_$(VM_PROVIDER)_$(TESTRUN_ID)"

# Test run for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
testrun.%: testrun_init.% testrun_tests.% testrun_finish.% ;

# Initialize test run for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
testrun_init.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
testrun_init.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
testrun_init.%: install_box.$$(VM_PROVIDER_ID) init_box.% startup_box.% ;

# Execute test run tests for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
testrun_tests.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
testrun_tests.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
testrun_tests.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
testrun_tests.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), test run ID: $(TESTRUN_ID)"
	$(if $(filter $(TESTRUN_ID),clockoffset), \
		$(eval VG_TEST_BOX_RUN_PARAMS = --clockoffset) \
	)
	$(if $(filter $(TESTRUN_ID),default), \
		$(eval VG_TEST_BOX_RUN_PARAMS = ) \
	)
	@bash $(TEST_DIR)/host/test_box.sh $(VG_TEST_ROOT_DIR)/$(VM_PROVIDER)/$(TESTRUN_ID) $(VG_TEST_BOX_RUN_PARAMS)

# Finish test run for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
testrun_finish.%: shutdown_box.% ;

# Install Vagrant box for given VM provider
# %: VM provider ID (vbx, vmw, ...)
install_box.%: VM_PROVIDER_ID = $*
install_box.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
install_box.%: VG_PROVIDER = $(VG_PROVIDER.$(VM_PROVIDER_ID))
install_box.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), Vagrant provider: $(VG_PROVIDER)"
	@bash $(TEST_DIR)/host/install_box.sh $(VG_TEST_BOX_NAME) $(DIST_DIR)/$(VM_PROVIDER)/$(VM_NAME).box $(VG_PROVIDER)

# Remove Vagrant box for given VM provider
# %: VM provider ID (vbx, vmw, ...)
remove_box.%: VM_PROVIDER_ID = $*
remove_box.%: VG_PROVIDER = $(VG_PROVIDER.$(VM_PROVIDER_ID))
remove_box.%:
	@echo "*** $@: Vagrant provider: $(VG_PROVIDER)"
	@-bash $(TEST_DIR)/host/remove_box.sh $(VG_TEST_BOX_NAME) $(VG_PROVIDER)

# Initialize Vagrant box instance for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
init_box.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
init_box.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
init_box.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
init_box.%: VG_PROVIDER = $(VG_PROVIDER.$(VM_PROVIDER_ID))
init_box.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), test run ID: $(TESTRUN_ID)"
	$(call check_valid_vm_provider_id,$(VM_PROVIDER_ID))
	$(call check_valid_testrun_id,$(TESTRUN_ID))
	$(if $(filter $(TESTRUN_ID),clockoffset), \
		$(eval VG_TEST_BOX_INIT_PARAMS = --vagrantfile $(TEST_DATA_DIR)/$(VM_PROVIDER)/Vagrantfile.clockoffset.erb --no-win-time-sync) \
	)
	$(if $(filter $(TESTRUN_ID),default), \
		$(eval VG_TEST_BOX_INIT_PARAMS = --vagrantfile $(TEST_DATA_DIR)/$(VM_PROVIDER)/Vagrantfile.erb) \
	)
	@bash $(TEST_DIR)/host/init_box.sh $(VG_TEST_BOX_NAME) $(VG_TEST_ROOT_DIR)/$(VM_PROVIDER)/$(TESTRUN_ID) $(TEST_RES_DIR) $(VG_PROVIDER) $(VG_TEST_BOX_INIT_PARAMS)

# Destroy Vagrant box for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
destroy_box.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
destroy_box.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
destroy_box.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
destroy_box.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), test run ID: $(TESTRUN_ID)"
	$(call check_valid_vm_provider_id,$(VM_PROVIDER_ID))
	$(call check_valid_testrun_id,$(TESTRUN_ID))
	@-bash $(TEST_DIR)/host/destroy_box.sh $(VG_TEST_ROOT_DIR)/$(VM_PROVIDER)/$(TESTRUN_ID)

# Startup Vagrant box for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
startup_box.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
startup_box.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
startup_box.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
startup_box.%: VG_PROVIDER = $(VG_PROVIDER.$(VM_PROVIDER_ID))
startup_box.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), test run ID: $(TESTRUN_ID)"
	$(call check_valid_vm_provider_id,$(VM_PROVIDER_ID))
	$(call check_valid_testrun_id,$(TESTRUN_ID))
	@bash $(TEST_DIR)/host/startup_box.sh -d "$(TEST_LOG_DIR)/vagrant_$(VM_PROVIDER)_$(TESTRUN_ID)" $(VG_TEST_ROOT_DIR)/$(VM_PROVIDER)/$(TESTRUN_ID) $(VG_PROVIDER)

# Shutdown Vagrant box for given provider and test run ID
# %: [VM Provider ID (vbx, vmw...)].[Test run ID (see TESTRUN_ID_LIST)]
shutdown_box.%: VM_PROVIDER_ID = $(word 1,$(subst .,$(SPACE),$*))
shutdown_box.%: TESTRUN_ID = $(word 2,$(subst .,$(SPACE),$*))
shutdown_box.%: VM_PROVIDER = $(VM_PROVIDER.$(VM_PROVIDER_ID))
shutdown_box.%:
	@echo "*** $@: VM provider: $(VM_PROVIDER), test run ID: $(TESTRUN_ID)"
	$(call check_valid_vm_provider_id,$(VM_PROVIDER_ID))
	$(call check_valid_testrun_id,$(TESTRUN_ID))
	@bash $(TEST_DIR)/host/shutdown_box.sh $(VG_TEST_ROOT_DIR)/$(VM_PROVIDER)/$(TESTRUN_ID)

# Check whether given VM provider ID is valid
define check_valid_vm_provider_id # $1: VM provider ID
	$(if $(filter $1,$(VM_PROVIDER_ID_LIST)),,$(error *** Error: Unkonwn VM provider ID: $1))
endef

# Check whether given testrun ID is valid
define check_valid_testrun_id # $1: VM provider ID
	$(if $(filter $1,$(TESTRUN_ID_LIST)),,$(error *** Error: Unkonwn test run ID: $1))
endef

