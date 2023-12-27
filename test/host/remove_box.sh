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
  echo -e "Usage: $0 BOX_NAME PROVIDER\n"
  echo "Remove Vagrant box"
  echo "BOX_NAME:  Name of Vagrant box to be removed"
  echo "PROVIDER:  Vagrant provider"
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
VG_BOX_NAME=$1
VG_PROVIDER=$2

echo "**************************************"
echo "*** Removing box \"$VG_BOX_NAME\""
echo "**************************************"
echo "Provider: $VG_PROVIDER"
echo ""

removeBox $VG_BOX_NAME $VG_PROVIDER || true

echo "Done"