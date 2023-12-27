### Connect generic goals to VMware-specific goals

# Test
test: test_vmw

# Clean
clean: clean_vmw


### VMware-specific goals

# Test VMware
.PHONY: test_vmw
test_vmw:
	$(call testrun_all,vmware,vmware_desktop)

# Clean VMware
.PHONY: clean_vmw
clean_vmw:
	$(call clean_all,vmware,vmware_desktop)
