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
  echo -e "Usage: $0 NAME BASE_DIR OS_TYPE CPU_COUNT RAM HDD VIDEO_RAM\n"
  echo "Create virtual machine with given parameters"
  echo "NAME:      Name of VM"
  echo "BASE_DIR:  Directory where VM is created"
  echo "OS_TYPE:   Operating system type"
  echo "CPU_COUNT: Number of CPUs"
  echo "RAM:       RAM size in MB"
  echo "HDD:       Harddisk size in MB"
  echo "VIDEO_RAM: Video RAM size in MB"
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
VM_OS_TYPE=$3
VM_CPU_COUNT=$4
VM_RAM=$5
VM_HDD=$6
VM_VIDEO_RAM=$7

echo "**************************************"
echo "*** Creating VM \"$VM_NAME\""
echo "**************************************"
echo "Base dir: $VM_BASE_DIR"
echo "Operating System: $VM_OS_TYPE"
echo "CPUs: $VM_CPU_COUNT"
echo "RAM: $VM_RAM MB"
echo "HD size: $VM_HDD MB"
echo "Video RAM: $VM_VIDEO_RAM MB"
echo ""

# Create base dir if required
if [ ! -d $VM_BASE_DIR ] ; then
  mkdir -p $VM_BASE_DIR
fi

# Create VM
echo "Creating VM \"$VM_NAME\" in \"$VM_BASE_DIR\"..."
VBoxManage createvm --name $VM_NAME --ostype $VM_OS_TYPE --basefolder $VM_BASE_DIR --register

# Add controller
echo "Adding SATA controller..."
VBoxManage storagectl $VM_NAME --name "SATA" --add sata --controller IntelAHCI

# Create virtual disk
VM_VDI=$VM_BASE_DIR/$VM_NAME/$VM_NAME.vdi
echo "Creating virtual disk \"$VM_VDI\"..."
VBoxManage createhd disk --filename $VM_VDI --size $VM_HDD

# Attach disk
echo "Attaching disk to controller..."
VBoxManage storageattach $VM_NAME --storagectl "SATA" --port 0 --device 0 --type hdd --medium $VM_VDI

# Configure VM
echo "Configuring VM..."
VBoxManage modifyvm $VM_NAME --memory $VM_RAM --vram $VM_VIDEO_RAM --cpus $VM_CPU_COUNT --ioapic on \
  --graphicscontroller vboxsvga --audio none --usbohci on --mouse usb --pae off --clipboard=hosttoguest

echo "Done creating VM \"$VM_NAME\""
