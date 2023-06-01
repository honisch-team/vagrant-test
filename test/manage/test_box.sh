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


# Test version string
testVersionStr() {
  # Get windows version from inside box
  echo "Executing test: VersionStr"
  echo " Executing test command..."
  STR=$(vagrant winrm --shell cmd --command "ver" | tr -d "\r" | sed -n 2p)
  STR_EXPECTED="Microsoft Windows [Version 6.1.7601]"
  echo "  Result  : $STR"
  echo "  Expected: $STR_EXPECTED"
  if [ "$STR" == "$STR_EXPECTED" ] ; then
    echo "  => Success"
    return 0
  else
    echo "  => Failure"
    return 1
  fi
}


# Test date and time
testDateTime() {
  # Get windows version from inside box
  echo "Executing test: DateTime"
  echo " Executing test command..."
  STR=$(vagrant winrm --shell cmd --command "date /T" | tr -d "\r")
  echo "  Result  : $STR"
}


# Display usage
display_usage() {
  echo -e "Usage: $0 TEST_DIR\n"
  echo "Test Vagrant box"
  echo "TEST_DIR:  Vagrant test environment dir"
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
VG_TEST_DIR=$1

echo "**************************************"
echo "*** Testing Vagrant box in \"$VG_TEST_DIR\""
echo "**************************************"

# Indicate test success / failure
TESTS_FAILED=0

cd $VG_TEST_DIR

# Test version string
testVersionStr || TESTS_FAILED=1

# Test date and time
testDateTime || TESTS_FAILED=1

# Check for test result
if [ $TESTS_FAILED -ne 0 ] ; then
  echo "There are FAILED tests"
  exit 1
else
  echo "All tests SUCCEEDED"
  exit 0
fi
