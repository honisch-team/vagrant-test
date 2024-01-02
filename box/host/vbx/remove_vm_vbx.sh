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
  echo -e "Usage: $0 NAME\n"
  echo "Remove virtual machine from disk."
  echo "NAME: Name of VM"
  echo ""
}


### Main code starts here

# Check for -h or --help
if [[ ($@ == "--help") || $@ == "-h" ]] ; then
  display_usage
  exit 0
fi

# Check for correct number of arguments
if [ $# -ne 1 ] ; then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1


echo "**************************************"
echo "*** Removing VM \"$VM_NAME\""
echo "**************************************"

# Get VM info
declare -A VM_INFO
EXIT_CODE=0
getVmInfo VM_INFO $VM_NAME || exit 1
echo "Checking whether VM is running..."

# If VM is running => power off
if [ "${VM_INFO[VMState]}" == "running" ] ; then
  echo "VM is running, stopping..."
  VBoxManage controlvm $VM_NAME poweroff
  sleep 5
  echo "VM is stopped"
else
  echo -e "VM not running"
fi

echo "Unregistering VM..."
VBoxManage unregistervm --delete "$VM_NAME"

# Remove VM files
VM_CFG_FILE=${VM_INFO[CfgFile]}
if [ -f $VM_CFG_FILE ] ; then
  $VM_DIR=$(dirname $VM_CFG_FILE)
  echo "Removing VM files from \"$VM_DIR\""
  rm -rf $VM_DIR || true
fi
echo "Done removing VM \"$VM_NAME\""

