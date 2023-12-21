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
source $SCRIPT_DIR/common_vbx.sh

# Display usage
display_usage() {
  echo -e "Usage: $0 NAME WORK_DIR INSTALL_MEDIA HOSTNAME USER PASSWORD\n"
  echo "Install operating system in virtual machine"
  echo "NAME:          Name of VM"
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
if [ $# -ne 6 ] ; then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1
VM_WORK_DIR=$2
VM_INSTALL_MEDIA=$3
VM_HOSTNAME=$4
VM_USER=$5
VM_PASSWORD=$6

echo "**************************************"
echo "*** Installing operating system in VM \"$VM_NAME\""
echo "**************************************"
echo "Work dir: $VM_WORK_DIR"
echo "Install media: $VM_INSTALL_MEDIA"
echo "Hostname: $VM_HOSTNAME"
echo "User: $VM_USER"
echo ""

VM_GUEST_TOOLS_ISO_LINUX="/usr/share/virtualbox/VBoxGuestAdditions.iso"
VM_GUEST_TOOLS_ISO_MAC="/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"

# Check for Guest Additions iso
echo -n "Checking for Guest Additions ISO..."
if [ -f "$VM_GUEST_TOOLS_ISO_LINUX" ] ; then
  echo "found: $VM_GUEST_TOOLS_ISO_LINUX"
  VM_GUEST_TOOLS_ISO=$VM_GUEST_TOOLS_ISO_LINUX
elif [ -f "$VM_GUEST_TOOLS_ISO_MAC" ] ; then
  echo "found: $VM_GUEST_TOOLS_ISO_MAC"
  VM_GUEST_TOOLS_ISO=$VM_GUEST_TOOLS_ISO_MAC
else
  echo "Error: Guest Additions ISO not found"
  exit 1
fi

# Create work dir if required
if [ ! -d $VM_WORK_DIR ] ; then
  mkdir -p $VM_WORK_DIR
fi

# Prepare floppy image
echo "Preparing floppy image..."
VM_FLOPPY_SRC_DIR=$VM_WORK_DIR/autoinst.flp.src
VM_FLOPPY_IMG=$VM_WORK_DIR/autoinst.img
if [ ! -d $VM_FLOPPY_SRC_DIR ] ; then
  mkdir -p $VM_FLOPPY_SRC_DIR
fi
VM_AUTO_UNATTENDED_XML=$SCRIPT_DIR/../common/autounattend.xml
sed -e "s/@@HOSTNAME@@/$VM_HOSTNAME/g;s/@@USERNAME@@/$VM_USER/g;s/@@PASSWORD@@/$VM_PASSWORD/g;s/@@POST_INSTALL_SCRIPT@@/post_install_1_vbx.bat/g" "$VM_AUTO_UNATTENDED_XML" > "$VM_FLOPPY_SRC_DIR/autounattend.xml"
bash $SCRIPT_DIR/../common/create_floppy_image.sh "$VM_FLOPPY_SRC_DIR" "$VM_FLOPPY_IMG"

# Provide additional install files
VM_INSTALL_FILES_SRC_DIR=$VM_WORK_DIR/install_files.src
VM_INSTALL_FILES_ISO=$VM_WORK_DIR/install_files.iso
if [ ! -d $VM_INSTALL_FILES_SRC_DIR ] ; then
  mkdir -p $VM_INSTALL_FILES_SRC_DIR
fi

# Provide scripts
cp $SCRIPT_DIR/post_install_*vbx.bat $VM_INSTALL_FILES_SRC_DIR/

# Create iso from install files dir
echo "Creating iso image containing additional install files..."
bash $SCRIPT_DIR/../common/create_iso_image.sh $VM_INSTALL_FILES_SRC_DIR $VM_INSTALL_FILES_ISO

# Preparing VM for unattended install
echo "Preparing VM for unattended install..."
# Attach floppy
echo "  Add floppy..."
VBoxManage storagectl $VM_NAME --name "Floppy" --add floppy
echo "  Attach floppy image..."
VBoxManage storageattach $VM_NAME --storagectl "Floppy" --port 0 --device 0 --type fdd --medium "$VM_FLOPPY_IMG"
# Attach install media
echo "  Attach install media..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$VM_INSTALL_MEDIA"
# Attach Guest Additions ISO
echo "  Attach Guest Additions ISO..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 2 --device 0 --type dvddrive --medium "$VM_GUEST_TOOLS_ISO"
# Attach install files ISO
echo "  Attach install files ISO..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 3 --device 0 --type dvddrive --medium "$VM_INSTALL_FILES_ISO"
# Set boot order
echo "  Set boot order..."
VBoxManage modifyvm $VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Start unattended install
echo "Starting unattended install..."
VBoxManage startvm $VM_NAME --type headless

# Wait for install to finish
echo "Waiting for install to finish..."
VBoxManage guestproperty wait $VM_NAME installation_finished --timeout 36000000 --fail-on-timeout
echo "Installation has finished"
VBoxManage guestproperty delete $VM_NAME installation_finished

# Shutdown VM
echo "Shutting down VM..."
stopVmViaPowerButton $VM_NAME

# Modify some VM settings
echo "Modifying VM settings..."
# Remove install media
echo "  Remove install media..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 1 --device 0 --medium none
# Remove Guest Additions ISO
echo "  Remove guest additions ISO..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 2 --device 0 --medium none
# Remove install files ISO
echo "  Remove install files ISO..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 3 --device 0 --medium none
# Remove floppy
echo "  Remove floppy..."
VBoxManage storagectl $VM_NAME --name "Floppy" --remove
# Set boot order
echo "  Set boot order..."
VBoxManage modifyvm $VM_NAME --boot1 disk --boot2 none --boot3 none --boot4 none

echo "Done installing operating system in VM \"$VM_NAME\""