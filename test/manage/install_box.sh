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
source $SCRIPT_DIR/common.sh

# Display usage
display_usage() {
  echo -e "Usage: $0 BOX_NAME BOX_FILE\n"
  echo "Install Vagrant box file"
  echo "BOX_NAME:  Name for Vagrant box"
  echo "BOX_FILE:  Vagrant box file to test"
  echo ""
}


### Main code starts here

# Check for -h or --help
if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then
  display_usage
  exit 0
fi

# Check for correct number of arguments
if [  $# -ne 2 ]
then
  display_usage
  exit 1
fi

# Read params
VG_BOX_NAME=$1
VG_BOX_FILE=$2

echo "**************************************"
echo "*** Installing Vagrant box file \"$VG_BOX_NAME\""
echo "**************************************"
echo "Box file: $VG_BOX_FILE"
echo ""

# Check if box installed
EXIT_CODE=0
isBoxInstalled $VG_BOX_NAME || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]
then
  # Add box
  echo "Adding box..."
  vagrant box add $VG_BOX_FILE --name $VG_BOX_NAME
else
  echo "Box is already installed"
fi

echo "Done"
