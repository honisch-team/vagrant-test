### VMware-specific goals

# VM provider name for VMware
VM_PROVIDER.vmw := vmware

# Vagrant provider name for VMware
VG_PROVIDER.vmw := vmware_desktop

# Test
test: test.vmw

# Clean
clean: clean.vmw
