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

# Test run types
TEST_RUN_TYPES := default clockoffset

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

# All test runs
define testrun_all # $1: VM provider, $2: Vagrant provider
	@echo "*** testrun_all: VM provider: $1, Vagrant provider: $2"
	$(foreach test_run_type,$(TEST_RUN_TYPES),
		$(call testrun,$1,$2,$(test_run_type))
	)
endef

# Clean all testruns
define clean_all # $1: VM provider, $2: Vagrant provider
	@echo "*** clean_all: VM provider: $1, Vagrant provider: $2"
	$(foreach test_run_type,$(TEST_RUN_TYPES),
		$(call destroy_box,$1,$(test_run_type))
		$(call clean_test_logs,$1,$(test_run_type))
	)
	$(call remove_box,$2)
endef

# Clean test logs
define clean_test_logs # $1: VM provider, $2: Test run type
	@-rm -rf "$(TEST_LOG_DIR)/vagrant_$(1)_$(2)"
endef

# Single test run
define testrun # $1: VM provider, $2: Vagrant provider, $3: Test run type
	@echo "*** testrun: VM provider: $1, Vagrant provider: $2, Test run type: $3"
	$(call test_run_init,$1,$2,$3)
	$(call test_run_tests,$1,$3)
	$(call test_run_finish,$1,$2,$3)
endef

# Initialize test run
define test_run_init # $1: VM provider, $2: Vagrant provider, $3: Test run type
	@echo "*** testrun_init: VM provider: $1, Vagrant provider: $2, Test run type: $3"
	$(call install_box,$1,$2)
	$(call init_box,$1,$3)
	$(call startup_box,$1,$3)
endef

# Install Vagrant box
define install_box # $1: VM provider, $2: Vagrant provider
	@bash $(TEST_DIR)/host/install_box.sh $(VG_TEST_BOX_NAME) $(DIST_DIR)/$(1)/$(VM_NAME).box $(2)
endef

# Remove Vagrant box
define remove_box # $1: Vagrant provider
	@-bash $(TEST_DIR)/host/remove_box.sh $(VG_TEST_BOX_NAME) $(1)
endef

# Initialize Vagrant box instance
define init_box # $1: VM provider, $2: Test run type
	@echo "*** init_box: VM provider: $1, Test run type: $2"
	$(if $(filter $2,clockoffset),
		$(eval VG_TEST_BOX_INIT_PARAMS = --vagrantfile $(TEST_DATA_DIR)/$(1)/Vagrantfile.clockoffset.erb --no-win-time-sync)
	)
	$(if $(filter $2,default),
		$(eval VG_TEST_BOX_INIT_PARAMS = --vagrantfile $(TEST_DATA_DIR)/$(1)/Vagrantfile.erb)
	)
	bash $(TEST_DIR)/host/init_box.sh $(VG_TEST_BOX_NAME) $(VG_TEST_ROOT_DIR)/$1/$2 $(TEST_RES_DIR) $(VG_TEST_BOX_INIT_PARAMS)
endef

# Destroy Vagrant box
define destroy_box # $1: VM provider, $2: Test run type
	@echo "*** destroy_box: VM provider: $1, Test run type: $2"
	@-bash $(TEST_DIR)/host/destroy_box.sh $(VG_TEST_ROOT_DIR)/$1/$2
endef

# Startup Vagrant box
define startup_box # $1: VM provider, $2: Test run type
	@echo "*** startup_box: VM provider: $1, Test run type: $2"
	@bash $(TEST_DIR)/host/startup_box.sh -d "$(TEST_LOG_DIR)/vagrant_$(1)_$(2)" $(VG_TEST_ROOT_DIR)/$1/$2
endef

# Shutdown Vagrant box
define shutdown_box # $1: VM provider, $2: Test run type
	@echo "*** shutdown_box: VM provider: $1, Test run type: $2"
	@bash $(TEST_DIR)/host/shutdown_box.sh $(VG_TEST_ROOT_DIR)/$1/$2
endef

# Execute test run tests
define test_run_tests # $1: VM provider, $2: Test run type
	@echo "*** test_run_tests: VM provider: $1, Test run type: $2"
	$(if $(filter $2,clockoffset),
		$(eval VG_TEST_BOX_RUN_PARAMS = --clockoffset)
	)
	$(if $(filter $2,default),
		$(eval VG_TEST_BOX_RUN_PARAMS = )
	)
	@bash $(TEST_DIR)/host/test_box.sh $(VG_TEST_ROOT_DIR)/$1/$2 $(VG_TEST_BOX_RUN_PARAMS)
endef

# Finish test run
define test_run_finish # $1: VM provider, $2: Vagrant provider, $3: Test run type
	@echo "*** test_run_finish: VM provider: $1, Vagrant provider: $2, Test run type: $3"
	$(call shutdown_box,$1,$3)
	$(call destroy_box,$1,$3)
endef
