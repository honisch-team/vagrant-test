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
  echo -e "Usage: $0 NAME BASE_DIR\n"
  echo "Remove virtual machine from disk."
  echo "NAME:     Name of VM"
  echo "BASE_DIR: Directory where VM is created"
  echo ""
}


### Main code starts here

# Check for -h or --help
if [[ ($@ == "--help") || $@ == "-h" ]] ; then
  display_usage
  exit 0
fi

# Check for correct number of arguments
if [ $# -ne 2 ] ; then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1
VM_BASE_DIR=$2

echo "**************************************"
echo "*** Removing VM \"$VM_NAME\""
echo "**************************************"
echo "Base dir: $VM_BASE_DIR"
echo ""

VM_DIR=$VM_BASE_DIR/$VM_NAME
VM_VMX=$VM_DIR/$VM_NAME.vmx

echo "Checking whether VM is running..."
VM_STATE=$(getVmState $VM_VMX)

# If VM is running => power off
if [ "$VM_STATE" == "running" ] ; then
  echo "VM is running, stopping..."
  vmrun stop $VM_VMX hard
  sleep 5
  echo "VM is stopped"
else
  echo -e "VM not running"
fi

if [ -f $VM_VMX ] ;  then
  echo "Deleting VM..."
  vmrun deleteVM $VM_VMX || true
fi

# Remove VM files
if [ -d $VM_DIR ] ;  then
  echo "Removing VM files from \"$VM_DIR\""
  rm -rf $VM_DIR || true
fi
echo "Done removing VM \"$VM_NAME\""

