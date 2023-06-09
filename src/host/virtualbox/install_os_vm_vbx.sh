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
  echo -e "Usage: $0 NAME INSTALL_MEDIA HOSTNAME USER PASSWORD\n"
  echo "Install operating system in virtual machine"
  echo "NAME:          Name of VM"
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
if [ $# -ne 5 ] ; then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1
VM_INSTALL_MEDIA=$2
VM_HOSTNAME=$3
VM_USER=$4
VM_PASSWORD=$5

echo "**************************************"
echo "*** Installing operating system in VM \"$VM_NAME\""
echo "**************************************"
echo "Install media: $VM_INSTALL_MEDIA"
echo "Hostname: $VM_HOSTNAME"
echo "User: $VM_USER"
echo ""

# Start unattended install
echo "Starting unattended install..."
VBoxManage unattended install $VM_NAME --iso=$VM_INSTALL_MEDIA --user=$VM_USER --password=$VM_PASSWORD --install-additions --country=US \
  --hostname=$VM_HOSTNAME.local --time-zone=UTC \
  --post-install-command="VBoxControl guestproperty set installation_finished y \
  & reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f \
  & shutdown /a \
  & shutdown /s /f /t 10"
VBoxManage startvm $VM_NAME --type headless

# Wait for install to finish
echo "Waiting for install to finish..."
VBoxManage guestproperty wait $VM_NAME installation_finished --timeout 36000000 --fail-on-timeout
echo "Installation has finished"
VBoxManage guestproperty delete $VM_NAME installation_finished

# Wait for VM to shut down
echo "Wait until VM stopped"
waitUntilVmStopped $VM_NAME

# Modify some VM settings
echo "Modifying VM settings..."
# Remove install media
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 1 --device 0 --medium none
# Remove Guest Additions ISO
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 2 --device 0 --medium none
# Remove floppy
VBoxManage storagectl $VM_NAME --name "Floppy" --remove
# Fix boot order
VBoxManage modifyvm $VM_NAME --boot1 disk --boot2 none --boot3 none --boot4 none

echo "Done installing operating system in VM \"$VM_NAME\""