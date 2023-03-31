# Root dir
ROOT_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST)))/..)

# Include common settings
include $(ROOT_DIR)/build/Makefile.common

# Vagrant box test name
VG_TEST_BOX_NAME := test-box

# Test data dir
TEST_DATA_DIR := $(TEST_DIR)/data

.PHONY: all clean test test_% box_%

# Make all
all: test

# Clean
clean: box_destroy box_remove

# Test
test: test_run_default test_run_clockoffset

# Default test run
test_run_default:
	@cd $(TEST_DIR) && $(MAKE) test_run

# Test run with clock offset
test_run_clockoffset: export VG_TEST_BOX_INIT_PARAMS=--vagrantfile $(TEST_DATA_DIR)/Vagrantfile.clockoffset.erb
test_run_clockoffset:
	@cd $(TEST_DIR) && $(MAKE) test_run

# Test run
test_run: test_run_init test_run_tests test_run_finish
	@echo $(VG_TEST_BOX_INIT_PARAMS)

# Initialize test run
test_run_init: box_install box_init box_startup

# Execute test run tests
test_run_tests:
	@bash $(TEST_DIR)/manage/test_box.sh $(VG_TEST_DIR)

# Finish test run
test_run_finish: box_shutdown box_destroy

# Install Vagrant box
box_install:
	@bash $(TEST_DIR)/manage/install_box.sh $(VG_TEST_BOX_NAME) $(DIST_DIR)/$(VM_NAME).box

# Initialize Vagrant box instance
box_init:
	@bash $(TEST_DIR)/manage/init_box.sh $(VG_TEST_BOX_NAME) $(VG_TEST_DIR) $(VG_TEST_BOX_INIT_PARAMS)

# Startup Vagrant box
box_startup:
	@bash $(TEST_DIR)/manage/startup_box.sh $(VG_TEST_DIR)

# Shutdown Vagrant box
box_shutdown:
	@bash $(TEST_DIR)/manage/shutdown_box.sh $(VG_TEST_DIR)

# Destroy Vagrant box
box_destroy:
	@-bash $(TEST_DIR)/manage/destroy_box.sh $(VG_TEST_DIR)

# Remove Vagrant box
box_remove:
	@-bash $(TEST_DIR)/manage/remove_box.sh $(VG_TEST_BOX_NAME)
