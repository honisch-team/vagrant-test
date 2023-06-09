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


# Test time difference
testTimeDiff() {
  local OPT_CLOCKOFFSET=$1
  # Compare host time with guest time
  echo "Executing test: TimeDiff"
  local EXPECTED_OFFSET_SECS=0
  if [ $OPT_CLOCKOFFSET -ne 0 ] ; then
    EXPECTED_OFFSET_SECS=31536000
  fi
  echo " Executing test command..."
  local EXIT_CODE=0
  vagrant winrm --shell cmd --command "cscript //NoLogo C:\\vagrant\\test_time.wsf /hostEpochSecs:$EPOCHSECONDS /maxDiffSecs:60 /expectedOffsetSecs:$EXPECTED_OFFSET_SECS" || EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ] ; then
    echo "  => Success"
    return 0
  else
    echo "  => Failure"
    return 1
  fi
}


# Display usage
display_usage() {
  echo -e "Usage: $0 TEST_DIR\n"
  echo "Test Vagrant box"
  echo "TEST_DIR:  Vagrant test environment dir"
  echo ""
  echo "Options:"
  echo "  -h, --help          display this help and exit"
  echo "  --clockoffset       Clock offset mode"
  echo ""
}


### Main code starts here

# Parse options
EXIT_CODE=0
VALID_ARGS=$(getopt -o h --long help,clockoffset --name "$0" -- "$@") || EXIT_CODE=$?
if [ $EXIT_CODE != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- ${VALID_ARGS}

# Set initial values
OPT_CLOCKOFFSET=0

# extract options and arguments into variables
while true ; do
  case "$1" in
    -h | --help)
      display_usage
      exit 0
      ;;
    --clockoffset)
      OPT_CLOCKOFFSET=1
      shift
      ;;
    --) # end of arguments
      shift
      break
      ;;
    *) # error
      >&2 echo "Unsupported option: $1"
      display_usage
      exit 1
      ;;
  esac
done

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
if [ $OPT_CLOCKOFFSET -ne 0 ] ; then
  echo "Expect guest clock offset"
fi
echo ""

# Indicate test success / failure
TESTS_FAILED=0

cd $VG_TEST_DIR

# Test version string
testVersionStr || TESTS_FAILED=1

# Test time difference
testTimeDiff $OPT_CLOCKOFFSET || TESTS_FAILED=1

# Check for test result
if [ $TESTS_FAILED -ne 0 ] ; then
  echo "There are FAILED tests"
  exit 1
else
  echo "All tests SUCCEEDED"
  exit 0
fi
