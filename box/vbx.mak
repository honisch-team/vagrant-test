### Connect generic goals to VirtualBox-specific goals

# Build virtual machine
build: build.vbx

# Package virtual machine
package: package.vbx

# Remove virtual machine
remove_vm: remove_vm.vbx

# Clean dist folder
dist_clean: dist_clean.vbx

# Clean work dir
work_clean: work_clean.vbx


### VirtualBox-specific goals

# Install operating system in VirtualBox VM (no prerequisites)
.PHONY: install_os_vm_nodeps.vbx
install_os_vm_nodeps.vbx: create_vm.vbx
	@bash $(BOX_DIR)/host/vbx/install_os_vm_vbx.sh $(VM_NAME) "$(BOX_DIR)/host/vbx/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)
#	@bash $(BOX_DIR)/host/vbx/install_os_vm_vbx.sh -d $(SRC_LOG_DIR)/vbx $(VM_NAME) "$(BOX_DIR)/host/vbx/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update VirtualBox VM after OS install (no prerequisites)
.PHONY: update_vm_nodeps.vbx
update_vm_nodeps.vbx:
	@bash $(BOX_DIR)/host/vbx/update_vm_vbx.sh $(VM_NAME) $(VM_USER) $(VM_PASSWORD) $(BOX_DIR)/guest $(INSTALL_MEDIA_DIR)/update-files $(BOX_DIR)/guest/vbx/work $(UPDATE_VM_OPTS)

# Package VirtualBox VM (no prerequisites)
.PHONY: package_nodeps.vbx
package_nodeps.vbx:
	@echo "Packaging VirtualBox VM..."
	@vagrant package $(VM_NAME) --base $(VM_NAME) --vagrantfile $(BOX_DIR)/package/vbx/Vagrantfile.pkg --output $(DIST_DIR)/vbx/$(VM_NAME).box

# Remove VirtualBox VM
.PHONY: remove_vm.vbx
remove_vm.vbx:
	@-bash $(BOX_DIR)/host/vbx/remove_vm_vbx.sh $(VM_NAME)

# Remove work dir
.PHONY: work_clean.vbx
work_clean.vbx:
	@-rm -rf $(BOX_DIR)/guest/vbx/work
