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
  echo "Startup Vagrant box"
  echo "TEST_DIR:  Vagrant test environment dir"
  echo ""
}


# Start box
start_box() (
  set -euo pipefail
  VG_DIR=$1

  # Change to vagrant dir
  cd $VG_DIR

  # Launch box, try multiple times due to issue with vmware_desktop provider
  MAX_RETRY_LOOPS=10
  echo "****************"
  echo "*** Starting vagrant box"
  echo "****************"
  EXIT_CODE=0
  vagrant up || EXIT_CODE=$?

  # Retry if not successful
  while [ $EXIT_CODE -ne 0 ] ; do
    # Check for max retries exceeded
    if [ $MAX_RETRY_LOOPS -eq 0 ] ; then
      echo "Exceeded max retries"
      return 1
    fi

    # Sleep and retry
    sleep 10
    ((MAX_RETRY_LOOPS--))
    echo "****************"
    echo "*** Retry starting vagrant box ($MAX_RETRY_LOOPS)"
    echo "****************"
    EXIT_CODE=0
    vagrant up || EXIT_CODE=$?
  done
  return 0
)


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
VG_TEST_DIR=$1

echo "**************************************"
echo "*** Starting Vagrant box in \"$VG_TEST_DIR\""
echo "**************************************"

# Start box
start_box $VG_TEST_DIR

echo "Done"
