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
  echo -e "Usage: $0 [OPTIONS] TEST_DIR PROVIDER\n"
  echo "Startup Vagrant box"
  echo "TEST_DIR:  Vagrant test environment dir"
  echo "PROVIDER:  Vagrant provider"
  echo ""
  echo "Options:"
  echo "  -h, --help            display this help and exit"
  echo "  -d, --debug-log=DIR   log directory for debug logging"
  echo ""
}


### Main code starts here

# Parse options
EXIT_CODE=0
VALID_ARGS=$(getopt -o hd: --long help,debug-log: --name "$0" -- "$@") || EXIT_CODE=$?
if [ $EXIT_CODE != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- ${VALID_ARGS}

# Set initial values
OPT_DEBUG_LOG=

# extract options and arguments into variables
while true ; do
  case "$1" in
    -h | --help)
      display_usage
      exit 0
      ;;
    -d | --debug-log)
      OPT_DEBUG_LOG="$2"
      shift 2
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
if [ $# -ne 2 ] ; then
  display_usage
  exit 1
fi

# Read params
VG_TEST_DIR=$1
VG_PROVIDER=$2

echo "**************************************"
echo "*** Starting Vagrant box in \"$VG_TEST_DIR\""
echo "**************************************"
echo "Provider: $VG_PROVIDER"
if [ "$OPT_DEBUG_LOG" != "" ] ; then
  echo "Debug log dir: $OPT_DEBUG_LOG"
fi
echo ""

# Start box
start_box $VG_TEST_DIR $VG_PROVIDER "$OPT_DEBUG_LOG"

echo "Done"
