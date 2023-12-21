#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR=$(dirname $BASH_SOURCE)

# Error handling
failure() {
  local lineno=$1
  local msg=$2
  echo -e "\n*** Failed at line $lineno: $msg"
  exit 1
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# Include common stuff
source $SCRIPT_DIR/common_vmw.sh

# Display usage
display_usage() {
  echo -e "Usage: $0 NAME BASE_DIR WORK_DIR INSTALL_MEDIA HOSTNAME USER PASSWORD\n"
  echo "Install operating system in virtual machine"
  echo "NAME:          Name of VM"
  echo "BASE_DIR:      Directory where VM is created"
  echo "WORK_DIR:      Working dir for intermediate files"
  echo "INSTALL_MEDIA: Path to install media"
  echo "HOSTNAME:      Hostname for virtual machine"
  echo "USER:          Username for admin user in virtual machine"
  echo "PASSWORD:      Password for admin user in virtual machine"
  echo ""
}


### Main code starts here

# Check for -h or --help
if [[ ($@ == "--help") || $@ == "-h" ]] ; then
  display_usage
  exit 0
fi

# Check for correct number of arguments
if [ $# -ne 7 ] ; then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1
VM_BASE_DIR=$2
VM_WORK_DIR=$3
VM_INSTALL_MEDIA=$4
VM_HOSTNAME=$5
VM_USER=$6
VM_PASSWORD=$7

echo "**************************************"
echo "*** Installing operating system in VM \"$VM_NAME\""
echo "**************************************"
echo "Base dir: $VM_BASE_DIR"
echo "Work dir: $VM_WORK_DIR"
echo "Install media: $VM_INSTALL_MEDIA"
echo "Hostname: $VM_HOSTNAME"
echo "User: $VM_USER"
echo ""

VM_DIR=$VM_BASE_DIR/$VM_NAME
VM_VMX=$VM_DIR/$VM_NAME.vmx
VMWARE_TOOLS_ISO="/Applications/VMware Fusion.app/Contents/Library/isoimages/x86_x64/windows.iso"

# Check for VMware tools iso
if [ ! -f "$VMWARE_TOOLS_ISO" ] ; then
  echo "VMware Tools ISO not found: $VMWARE_TOOLS_ISO"
  return 1
fi

# Create work dir if required
if [ ! -d $VM_WORK_DIR ] ; then
  mkdir -p $VM_WORK_DIR
fi

# Prepare floppy image
echo "Preparing floppy image..."
VM_FLOPPY_SRC_DIR=$VM_WORK_DIR/autoinst.flp.src
VM_FLOPPY_DMG=$VM_WORK_DIR/autoinst.dmg
VM_FLOPPY_FLP=$VM_WORK_DIR/autoinst.flp
if [ ! -d $VM_FLOPPY_SRC_DIR ] ; then
  mkdir -p $VM_FLOPPY_SRC_DIR
fi
sed -e "s/@@HOSTNAME@@/$VM_HOSTNAME/g;s/@@USERNAME@@/$VM_USER/g;s/@@PASSWORD@@/$VM_PASSWORD/g" "$SCRIPT_DIR/autounattend.xml" > "$VM_FLOPPY_SRC_DIR/autounattend.xml"
# hdiutil always creates floppy image file as *.dmg
hdiutil create -size 1440k -fs "MS-DOS FAT12" -layout NONE -srcfolder "$VM_FLOPPY_SRC_DIR" -format UDRW -ov "$VM_FLOPPY_DMG"
# Rename floppy image file to *.flp so it works in VMware
mv "$VM_FLOPPY_DMG" "$VM_FLOPPY_FLP"

# Provide additional install files
VM_INSTALL_FILES_SRC_DIR=$VM_WORK_DIR/install_files.src
VM_INSTALL_FILES_ISO=$VM_WORK_DIR/install_files.iso
if [ ! -d $VM_INSTALL_FILES_SRC_DIR ] ; then
  mkdir -p $VM_INSTALL_FILES_SRC_DIR
fi

# Download KB4474419 required by VMware tools
echo "Downloading KB4474419..."
KB4474419_URL=https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2019/09/windows6.1-kb4474419-v3-x86_0f687d50402790f340087c576886501b3223bec6.msu
(cd $VM_INSTALL_FILES_SRC_DIR && curl -o kb4474419.msu $KB4474419_URL)

# Provide scripts
cp $SCRIPT_DIR/vmw_post_install* $VM_INSTALL_FILES_SRC_DIR/
cp $SCRIPT_DIR/vmw_on_logon.bat $VM_INSTALL_FILES_SRC_DIR/

# Create iso from install files dir
echo "Creating iso image containing additional install files"
hdiutil makehybrid -iso -joliet -o $VM_INSTALL_FILES_ISO $VM_INSTALL_FILES_SRC_DIR

# Preparing VM for unattended install
echo "Preparing VM for unattended install..."
perl $SCRIPT_DIR/vmx_cmd.pl $VM_VMX set floppy0.fileType=file "floppy0.fileName=$VM_FLOPPY_FLP" floppy0.clientDevice=FALSE \
  "sata0:0.deviceType=cdrom-image" "sata0:0.fileName=$VM_INSTALL_MEDIA" "sata0:0.present=TRUE" \
  "sata0:1.deviceType=cdrom-image" "sata0:1.fileName=$VMWARE_TOOLS_ISO" "sata0:1.present=TRUE" \
  "sata0:2.deviceType=cdrom-image" "sata0:2.fileName=$VM_INSTALL_FILES_ISO" "sata0:2.present=TRUE" \
  bios.bootOrder=hdd,cdrom

# Start unattended install
echo "Starting unattended install..."
startVm $VM_VMX

# Wait for install to finish
echo "Waiting for install to finish..."
waitForGuestVar $VM_VMX installation_finished

echo "Shutdown guest..."
runCommandInVm $VM_VMX "shutdown /a & shutdown /s /f /t 10"

# Wait for VM to shut down
echo "Wait until VM stopped"
waitUntilVmStopped $VM_VMX

# Modify some VM settings
echo "Modifying VM settings..."
# Remove Guest Additions ISO, install media, floppy
perl $SCRIPT_DIR/vmx_cmd.pl $VM_VMX remove "floppy0.*" "sata0:0.*" "sata0:1.*" "sata0:2.*"
# Fix boot order
perl $SCRIPT_DIR/vmx_cmd.pl $VM_VMX set bios.bootOrder=hdd

echo "Done installing operating system in VM \"$VM_NAME\""