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

# Download tools for setup
downloadTools() {
  local TOOLS_DIR=$1

  # Download "sdelete"
  echo "Downloading Sysinternals SDelete..."
  local SDELETE_URL=https://download.sysinternals.com/files/SDelete.zip
  (cd $TOOLS_DIR && curl -o a.zip $SDELETE_URL && unzip -o a.zip && rm a.zip)
  
  # Download KB3138612 to fix Windows Update
  echo "Downloading KB3138612..."
  local KB3138612_URL=https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2016/02/windows6.1-kb3138612-x86_6e90531daffc13bc4e92ecea890e501e807c621f.msu
  (cd $TOOLS_DIR && curl -o kb3138612.msu $KB3138612_URL)
}


# Display usage
display_usage() {
  echo -e "Usage: $0 [OPTION] NAME USER PASSWORD SRC_DIR\n"
  echo "Update virtual machine after operating system installation"
  echo "NAME:     Name of VM"
  echo "USER:     Username for VM logon"
  echo "PASSWORD: Password for VM logon"
  echo "SRC_DIR:  Directory with files to copy to VM and run"
  echo ""
  echo "Options:"
  echo "  -h, --help       display this help and exit"
  echo "  -d, --debug      run in debug mode (skip file cleanup etc.)"
  echo ""
}


### Main code starts here

# Parse options
EXIT_CODE=0
VALID_ARGS=$(getopt -o hd --long help,debug --name "$0" -- "$@") || EXIT_CODE=$?
if [ $EXIT_CODE != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- ${VALID_ARGS}

# Set initial values
OPT_DEBUG_MODE=0

# extract options and arguments into variables
while true ; do
  case "$1" in
    -h | --help )
      display_usage
      exit 0
      ;;
    -d | --debug )
      OPT_DEBUG_MODE=1
      shift
      ;;
    -- ) # end of arguments
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
if [ $# -ne 4 ]
then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1
VM_USER=$2
VM_PASSWORD=$3
VM_SRC_DIR=$4


echo "**************************************"
echo "*** Updating VM \"$VM_NAME\" after operating system install"
echo "**************************************"
if [ "$OPT_DEBUG_MODE" -ne 0 ]
then
  echo "Debug mode: enabled"
  echo ""
fi

# Download tools for setup
downloadTools $VM_SRC_DIR

# Startup VM
echo "Starting VM \"$VM_NAME\"..."
VBoxManage startvm $VM_NAME --type headless
waitUntilVmStartupComplete $VM_NAME

# Run update
echo "Copying update files from \"$VM_SRC_DIR\" to VM..."
VBoxManage guestcontrol $VM_NAME mkdir --username=$VM_USER --password=$VM_PASSWORD "C:\\temp" || echo "Ignoring error"
VBoxManage guestcontrol $VM_NAME copyto --username=$VM_USER --password=$VM_PASSWORD --target-directory "C:\\Temp" $VM_SRC_DIR

echo "Running update scripts..."
VM_SRC_DIR_BASE=$(basename $VM_SRC_DIR)
VM_GUEST_PARAMS=
if [ "$OPT_DEBUG_MODE" -ne 0 ]
then
  echo "Debug mode: Adding parameter \"DEBUG\" to update script"
  VM_GUEST_PARAMS=DEBUG
fi
SCRIPT_COUNTER=1
MAX_UPDATE_LOOPS=10
while [ -f $VM_SRC_DIR/run_update_${SCRIPT_COUNTER}.bat ]
do
  # Abort after maximum of update loops has been reached
  let MAX_UPDATE_LOOPS--
  if [ $MAX_UPDATE_LOOPS -eq 0 ]
  then
    echo "Exceeded max update loops"
    return 1
  fi

  # Run script
  echo "Running run_update_${SCRIPT_COUNTER}.bat ($MAX_UPDATE_LOOPS)"
  EXIT_CODE=0
  VBoxManage guestcontrol $VM_NAME run --username=$VM_USER --password=$VM_PASSWORD --exe cmd.exe -- /c "C:\\Temp\\$VM_SRC_DIR_BASE\\run_update_${SCRIPT_COUNTER}.bat" $VM_GUEST_PARAMS || EXIT_CODE=$?
  echo "Script returned $EXIT_CODE (VBoxManage adds 32 to non-zero script exit codes)"
  case "$EXIT_CODE" in
  0) # Script exit code 0: Success, run next script
    echo "Success, continue with next script"
    let SCRIPT_COUNTER++
    ;;
  34)  # Script exit code 2: Success, reboot and run next script
    echo "Success, continue with next script after restart"
    # Wait for VM shutdown
    waitUntilVmStopped $VM_NAME
    # Startup VM again
    echo "Starting VM $VM_NAME..."
    VBoxManage startvm $VM_NAME --type headless
    waitUntilVmStartupComplete $VM_NAME
    let SCRIPT_COUNTER++
    ;;
  35) # Script exit code 3: Success, reboot and re-run the script
    echo "Success, restart and call script again"
    # Wait for VM shutdown
    waitUntilVmStopped $VM_NAME
    # Startup VM again
    echo "Starting VM $VM_NAME..."
    VBoxManage startvm $VM_NAME --type headless
    waitUntilVmStartupComplete $VM_NAME
    ;;
  36) # Script exit code 4: Success, run same script again
    echo "Success, call script again"
    ;;
  *) # Treat all other exit codes as error
    echo "Script error occurred"
    exit 1
    ;;
  esac

done

# Cleanup
if [ "$OPT_DEBUG_MODE" -eq 0 ]
then
  echo "Removing files from VM"
  VBoxManage guestcontrol $VM_NAME rmdir --username=$VM_USER --password=$VM_PASSWORD --recursive "C:\\Temp"
else
  echo "Debug mode: Skip removing files from VM"
fi

# Shutdown VM
echo "Shutting down VM..."
stopVmViaPowerButton $VM_NAME

echo "Done"