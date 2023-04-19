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

# Display usage
display_usage() {
  echo -e "Usage: $0 NAME BASE_DIR VAGRANT_FILE OUTPUT_FILE\n"
  echo "Package virtual machine as Vagrant box"
  echo "NAME:          Name of VM"
  echo "BASE_DIR:      Directory where VM is created"
  echo "VAGRANT_FILE:  Vagrant file for package"
  echo "WORK_DIR:      Working dir for intermediate files"
  echo "BOX_FILE:      Output box file"
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
VM_BASE_DIR=$2
VM_VAGRANT_FILE=$3
VM_WORK_DIR=$4
VM_BOX_FILE=$5

echo "**************************************"
echo "*** Packaging VM \"$VM_NAME\""
echo "**************************************"
echo "Base dir: $VM_BASE_DIR"
echo "Work dir: $VM_WORK_DIR"
echo "Vagrant file: $VM_VAGRANT_FILE"
echo "Box file: $VM_BOX_FILE"
echo ""

VM_DIR=$VM_BASE_DIR/$VM_NAME
if [ ! -d $VM_DIR ] ; then
  mkdir -p $VM_DIR
fi

# Create work dir if required
if [ ! -d $VM_WORK_DIR ] ; then
  mkdir -p $VM_WORK_DIR
fi


# Copy VM files
echo "Copying VM files to \"$VM_WORK_DIR\"..."
cp $VM_DIR/*.vmx $VM_WORK_DIR/
cp $VM_DIR/*.nvram $VM_WORK_DIR/
cp $VM_DIR/*.vmsd $VM_WORK_DIR/
cp $VM_DIR/*.vmxf $VM_WORK_DIR/
cp $VM_DIR/*.vmdk $VM_WORK_DIR/

# Copy additional files
echo "Copying additional files to \"$VM_WORK_DIR\"..."
cp $SCRIPT_DIR/metadata.json $VM_WORK_DIR/
cp $SCRIPT_DIR/Vagrantfile.internal $VM_WORK_DIR/Vagrantfile
mkdir -p  $VM_WORK_DIR/include
cp $VM_VAGRANT_FILE $VM_WORK_DIR/include/_Vagrantfile

# Defragmenting and shrinking virtual disk
echo "Defragmenting virtual disk..."
vmware-vdiskmanager -d $VM_WORK_DIR/$VM_NAME.vmdk
echo "Shrinking virtual disk..."
vmware-vdiskmanager -k $VM_WORK_DIR/$VM_NAME.vmdk

# Create .box file
echo "Creating .box file..."
VM_BOX_DIR=$(dirname $VM_BOX_FILE)
if [ ! -d $VM_BOX_DIR ] ; then
  mkdir -p $VM_BOX_DIR
fi
cd $VM_WORK_DIR
tar cvzf $VM_BOX_FILE ./*

echo "Done packaging VM \"$VM_NAME\""
