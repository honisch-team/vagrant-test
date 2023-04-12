# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/Makefile.common

# Vagrant box test name
VG_TEST_BOX_NAME := test-box

# Test data dir
TEST_DATA_DIR := $(TEST_DIR)/data

# Make all
.PHONY: all
all: test

# Clean
.PHONY: clean
clean: destroy_box remove_box

# Test
.PHONY: test
test: test_run_default test_run_clockoffset

# Default test run
.PHONY: test_run_default
test_run_default:
	@cd $(TEST_DIR) && $(MAKE) test_run

# Test run with clock offset
.PHONY: test_run_clockoffset
test_run_clockoffset: export VG_TEST_BOX_INIT_PARAMS=--vagrantfile $(TEST_DATA_DIR)/Vagrantfile.clockoffset.erb
test_run_clockoffset:
	@cd $(TEST_DIR) && $(MAKE) test_run

# Test run
.PHONY: test_run
test_run: test_run_init test_run_tests test_run_finish
	@echo $(VG_TEST_BOX_INIT_PARAMS)

# Initialize test run
.PHONY: test_run_init
test_run_init: install_box init_box startup_box

# Execute test run tests
.PHONY: test_run_tests
test_run_tests:
	@bash $(TEST_DIR)/manage/test_box.sh $(VG_TEST_DIR)

# Finish test run
.PHONY: test_run_finish
test_run_finish: shutdown_box destroy_box

# Install Vagrant box
.PHONY: install_box
install_box:
	@bash $(TEST_DIR)/manage/install_box.sh $(VG_TEST_BOX_NAME) $(DIST_DIR)/$(VM_NAME).box

# Initialize Vagrant box instance
.PHONY: init_box
init_box:
	@bash $(TEST_DIR)/manage/init_box.sh $(VG_TEST_BOX_NAME) $(VG_TEST_DIR) $(VG_TEST_BOX_INIT_PARAMS)

# Startup Vagrant box
.PHONY: startup_box
startup_box:
	@bash $(TEST_DIR)/manage/startup_box.sh $(VG_TEST_DIR)

# Shutdown Vagrant box
.PHONY: shutdown_box
shutdown_box:
	@bash $(TEST_DIR)/manage/shutdown_box.sh $(VG_TEST_DIR)

# Destroy Vagrant box
.PHONY: destroy_box
destroy_box:
	@-bash $(TEST_DIR)/manage/destroy_box.sh $(VG_TEST_DIR)

# Remove Vagrant box
.PHONY: remove_box
remove_box:
	@-bash $(TEST_DIR)/manage/remove_box.sh $(VG_TEST_BOX_NAME)
