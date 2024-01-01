### VM-specific settings

# VM name and description
VM_NAME         := win7sp1-ent-x86-enu
VM_DESCRIPTION  := Windows 7 SP1 Enterprise x86 EN-US

# Install media
VM_INSTALL_MEDIA_FILE := install.iso

# Operating system, virtual hardware etc.
VM_OS_TYPE.vbx  := Windows7
VM_OS_TYPE.vmw  := windows7
VM_HOSTNAME     := win7x86
VM_CPU_COUNT    := 2
VM_RAM_MB       := 2048
VM_VIDEO_RAM_MB := 64
VM_HDD_SIZE_MB  := 40000

# Username / password of VM user
VM_USER     := vagrant
VM_PASSWORD := vagrant
