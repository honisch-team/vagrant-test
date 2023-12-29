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
	@bash $(SRC_DIR)/host/vmware/install_os_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" "$(SRC_DIR)/host/vmware/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update VMware VM after OS install (no prerequisites)
.PHONY: update_vm_nodeps.vmw
update_vm_nodeps.vmw: install_os_vm.vmw
	@bash $(SRC_DIR)/host/vmware/update_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(VM_USER) $(VM_PASSWORD) $(SRC_DIR)/guest $(SRC_DIR)/guest/vmware/work $(UPDATE_VM_OPTS)

# Package VMware VM
.PHONY: package.vmw
package.vmw:
	@bash $(SRC_DIR)/package/vmware/package_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(SRC_DIR)/package/vmware/Vagrantfile.pkg "$(SRC_DIR)/package/vmware/work" $(DIST_DIR)/vmware/$(VM_NAME).box

# Remove VMware VM
.PHONY: remove_vm.vmw
remove_vm.vmw:
	@-bash $(SRC_DIR)/host/vmware/remove_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware"

# Remove work dir
.PHONY: work_clean.vmw
work_clean.vmw:
	@-rm -rf $(SRC_DIR)/package/vmware/work
	@-rm -rf $(SRC_DIR)/host/vmware/work
	@-rm -rf $(SRC_DIR)/guest/vmware/work
