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
  echo -e "Usage: $0 [OPTION] BOX_NAME TEST_DIR RES_DIR\n"
  echo "Install Vagrant box file"
  echo "BOX_NAME:  Name for Vagrant box"
  echo "TEST_DIR:  Vagrant test environment dir"
  echo "RES_DIR:   Dir containing test resources to be copied to TEST_DIR"
  echo ""
  echo "Options:"
  echo "  -h, --help                display this help and exit"
  echo "  -v, --vagrantfile=FILE    initialize box with given Vagrantfile template"
  echo "  -t, --no-win-time-sync    initialize box with given Vagrantfile template"

  echo ""
}


### Main code starts here

# Parse options
EXIT_CODE=0
VALID_ARGS=$(getopt -o hv:t --long help,vagrantfile:,no-win-time-sync --name "$0" -- "$@") || EXIT_CODE=$?
if [ $EXIT_CODE != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- ${VALID_ARGS}

# Set initial values
OPT_VAGRANT_FILE=
OPT_NO_WIN_TIME_SYNC=0

# extract options and arguments into variables
while true ; do
  case "$1" in
    -h | --help)
      display_usage
      exit 0
      ;;
    -v | --vagrantfile)
      OPT_VAGRANT_FILE="$2"
      shift 2
      ;;
    -t | --no-win-time-sync)
      OPT_NO_WIN_TIME_SYNC=1
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
if [ $# -ne 3 ] ; then
  display_usage
  exit 1
fi

# Read params
VG_BOX_NAME=$1
VG_TEST_DIR=$2
VG_RES_DIR=$3

echo "**************************************"
echo "*** Initialize Vagrant box \"$VG_BOX_NAME\""
echo "**************************************"
echo "Test environment dir: $VG_TEST_DIR"
echo "Test resources dir: $VG_RES_DIR"
if [ "$OPT_VAGRANT_FILE" != "" ] ; then
  echo "Vagrantfile template: $OPT_VAGRANT_FILE"
fi
if [ $OPT_NO_WIN_TIME_SYNC -eq 1 ] ; then
  echo "Disable Windows time sync"
fi
echo ""

# Create test dir if required
if [ ! -d $VG_TEST_DIR ] ; then
  mkdir $VG_TEST_DIR
fi

# Init environment
echo "Initializing Vagrant test environment in \"$VG_TEST_DIR\""
if [ "$OPT_VAGRANT_FILE" != "" ] ; then
  (cd $VG_TEST_DIR && vagrant init --force --template $OPT_VAGRANT_FILE $VG_BOX_NAME)
else
  (cd $VG_TEST_DIR && vagrant init --force -m $VG_BOX_NAME)
fi

# Copy test resources to vagrant dir
echo "Copying test resouces from \"$VG_RES_DIR\" to test env. dir"
cp "$VG_RES_DIR/"* "$VG_TEST_DIR"

# Disable Windows time sync
if [ $OPT_NO_WIN_TIME_SYNC -eq 1 ] ; then
  echo "Disable Windos time sync: Start VM"
  start_box $VG_TEST_DIR "--no-provision"
  echo "Disable Windos time sync: Modify registry"
  (cd $VG_TEST_DIR && vagrant winrm --shell cmd --command "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\services\\W32Time\\Parameters\" /v Type /t REG_SZ /d NoSync /f")
  echo "Disable Windos time sync: Stop box"
  (cd $VG_TEST_DIR && vagrant halt)
fi

echo "Done"
