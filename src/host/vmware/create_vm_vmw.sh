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

# Create VM dir if required
VM_DIR=$VM_BASE_DIR/$VM_NAME
if [ ! -d $VM_DIR ] ; then
  mkdir -p $VM_DIR
fi

# Create VM
echo "Creating VM \"$VM_NAME\" in \"$VM_DIR\"..."
VM_VMX=$VM_DIR/$VM_NAME.vmx
cp $SCRIPT_DIR/template.vmx $VM_VMX
perl $SCRIPT_DIR/vmx_cmd.pl $VM_VMX set displayName=$VM_NAME nvram=$VM_NAME.nvram guestOS=$VM_OS_TYPE numvcpus=$VM_CPU_COUNT \
  memsize=$VM_RAM svga.graphicsMemoryKB=$(($VM_VIDEO_RAM*1024))

# Create virtual disk
VM_VMDK=$VM_DIR/$VM_NAME.vmdk
echo "Creating virtual disk \"$VM_VMDK\"..."
vmware-vdiskmanager -c -a lsilogic -s ${VM_HDD}MB -t 1 $VM_VMDK

# Attach disk
echo "Attaching disk to controller..."
perl $SCRIPT_DIR/vmx_cmd.pl $VM_VMX set "scsi0:0.fileName=$VM_NAME.vmdk" "scsi0:0.present=TRUE"

echo "Done creating VM \"$VM_NAME\""
