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
  echo -e "Usage: $0 TEST_DIR\n"
  echo "Destroy Vagrant box instance"
  echo "TEST_DIR:  Vagrant test environment dir"
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
if [  $# -ne 1 ]
then
  display_usage
  exit 1
fi

# Read params
VG_TEST_DIR=$1

echo "**************************************"
echo "*** Destroy box instance in \"$VG_TEST_DIR\""
echo "**************************************"

destroyBox $VG_TEST_DIR || true

echo "Done"