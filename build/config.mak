### VM-specific settings

# VM name and description
VM_NAME         := win7sp1-ent-x86-enu
VM_DESCRIPTION  := Windows 7 SP1 Enterprise x86 EN-US

# Install media
VM_INSTALL_MEDIA_URL  := https://archive.org/download/en_windows_7_enterprise_with_sp1_x86_dvd_u_677710_202006/en_windows_7_enterprise_with_sp1_x86_dvd_u_677710.iso
VM_INSTALL_MEDIA_FILE := en_windows_7_enterprise_with_sp1_x86_dvd_u_677710.iso
VM_INSTALL_MEDIA_SHA1 := 4e0450ac73ab6f9f755eb422990cd9c7a1f3509c

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
