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

# Install operating system in VirtualBox VM
.PHONY: install_os_vm.vbx
install_os_vm.vbx: | create_vm.vbx
	@bash $(SRC_DIR)/host/virtualbox/install_os_vm_vbx.sh $(VM_NAME) "$(SRC_DIR)/host/virtualbox/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)
#	@bash $(SRC_DIR)/host/virtualbox/install_os_vm_vbx.sh -d $(SRC_LOG_DIR)/virtualbox $(VM_NAME) "$(SRC_DIR)/host/virtualbox/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update VirtualBox VM after OS install
.PHONY: update_vm.vbx
update_vm.vbx: | install_os_vm.vbx
	@bash $(SRC_DIR)/host/virtualbox/update_vm_vbx.sh $(VM_NAME) $(VM_USER) $(VM_PASSWORD) $(SRC_DIR)/guest $(SRC_DIR)/guest/virtualbox/work $(UPDATE_VM_OPTS)

# Package VirtualBox VM
.PHONY: package.vbx
package.vbx:
	@echo "Packaging VirtualBox VM..."
	@vagrant package $(VM_NAME) --base $(VM_NAME) --vagrantfile $(SRC_DIR)/package/virtualbox/Vagrantfile.pkg --output $(DIST_DIR)/virtualbox/$(VM_NAME).box

# Remove VirtualBox VM
.PHONY: remove_vm.vbx
remove_vm.vbx:
	@-bash $(SRC_DIR)/host/virtualbox/remove_vm_vbx.sh $(VM_NAME)

# Remove work dir
.PHONY: work_clean.vbx
work_clean.vbx:
	@-rm -rf $(SRC_DIR)/guest/virtualbox/work
