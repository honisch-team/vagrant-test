### Connect generic goals to VMware-specific goals

# Build virtual machine
build: build.vmw

# Package virtual machine
package: package.vmw

# Remove virtual machine
remove_vm: remove_vm.vmw

# Clean dist folder
dist_clean: dist_clean.vmw

# Clean work dir
work_clean: work_clean.vmw


### VMware-specific goals

# Install operating system in VMware VM (no prerequisites)
.PHONY: install_os_vm_nodeps.vmw
install_os_vm_nodeps.vmw: create_vm.vmw
	@bash $(BOX_DIR)/host/vmware/install_os_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" "$(BOX_DIR)/host/vmware/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update VMware VM after OS install (no prerequisites)
.PHONY: update_vm_nodeps.vmw
update_vm_nodeps.vmw:
	@bash $(BOX_DIR)/host/vmware/update_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(VM_USER) $(VM_PASSWORD) $(BOX_DIR)/guest $(BOX_DIR)/guest/vmware/work $(UPDATE_VM_OPTS)

# Package VMware VM (no prerequisites)
.PHONY: package_nodeps.vmw
package_nodeps.vmw:
	@bash $(BOX_DIR)/package/vmware/package_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(BOX_DIR)/package/vmware/Vagrantfile.pkg "$(BOX_DIR)/package/vmware/work" $(DIST_DIR)/vmware/$(VM_NAME).box

# Remove VMware VM
.PHONY: remove_vm.vmw
remove_vm.vmw:
	@-bash $(BOX_DIR)/host/vmware/remove_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware"

# Remove work dir
.PHONY: work_clean.vmw
work_clean.vmw:
	@-rm -rf $(BOX_DIR)/package/vmware/work
	@-rm -rf $(BOX_DIR)/host/vmware/work
	@-rm -rf $(BOX_DIR)/guest/vmware/work
