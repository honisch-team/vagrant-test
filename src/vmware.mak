### Connect generic goals to VMware-specific goals

# Build virtual machine
build: build_vmw

# Package virtual machine
package: package_vmw

# Remove virtual machine
remove_vm: remove_vm_vmw

# Clean dist folder
dist_clean: dist_clean_vmw

# Clean work dir
work_clean: work_clean_vmw


### VMware-specific goals

# Build VMware VM
.PHONY: build_vmw
build_vmw: create_vm_vmw install_os_vm_vmw update_vm_vmw

# Create VMware VM
.PHONY: create_vm_vmw
create_vm_vmw:
	@bash $(SRC_DIR)/host/vmware/create_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(VM_OS_TYPE_VMW) $(VM_CPU_COUNT) $(VM_RAM_MB) $(VM_HDD_SIZE_MB) $(VM_VIDEO_RAM_MB)

# Install operating system in VMware VM
.PHONY: install_os_vm_vmw
install_os_vm_vmw:
	@bash $(SRC_DIR)/host/vmware/install_os_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" "$(SRC_DIR)/host/vmware/work" "$(INSTALL_MEDIA_DIR)/$(VM_INSTALL_MEDIA_FILE)" $(VM_HOSTNAME) $(VM_USER) $(VM_PASSWORD)

# Update VMware VM after OS install
.PHONY: update_vm_vmw
update_vm_vmw:
	@bash $(SRC_DIR)/host/vmware/update_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(VM_USER) $(VM_PASSWORD) $(SRC_DIR)/guest $(SRC_DIR)/guest/vmware/work $(UPDATE_VM_OPTS)

# Package VMware VM
.PHONY: package_vmw
package_vmw:
	@bash $(SRC_DIR)/package/vmware/package_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware" $(SRC_DIR)/package/vmware/Vagrantfile.pkg "$(SRC_DIR)/package/vmware/work" $(DIST_DIR)/vmware/$(VM_NAME).box

# Remove VMware VM
.PHONY: PHONY
remove_vm_vmw:
	@-bash $(SRC_DIR)/host/vmware/remove_vm_vmw.sh $(VM_NAME) "$(VM_BASE_DIR)/vmware"

# Remove VMware VM from dist
.PHONY: dist_clean_vmw
dist_clean_vmw:
	@-rm $(DIST_DIR)/vmware/*

# Remove work dir
.PHONY: work_clean_vmw
work_clean_vmw:
	@-rm -rf $(SRC_DIR)/package/vmware/work
	@-rm -rf $(SRC_DIR)/host/vmware/work
	@-rm -rf $(SRC_DIR)/guest/vmware/work
