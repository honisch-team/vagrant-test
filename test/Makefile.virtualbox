### Connect generic goals to VirtualBox-specific goals

# Test
test: test_vbx

# Clean
clean: clean_vbx


### VirtualBox-specific goals

# Test VirtualBox
.PHONY: test_vbx
test_vbx:
	$(call testrun_all,virtualbox,virtualbox)

# Clean VirtualBox
.PHONY: clean_vbx
clean_vbx:
	$(call clean_all,virtualbox,virtualbox)
