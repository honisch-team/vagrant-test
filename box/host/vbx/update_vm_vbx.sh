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
source $SCRIPT_DIR/common_vbx.sh

# Download tools for setup
downloadTools() {
  local TOOLS_DIR=$1

  # Download "sdelete"
  echo "Downloading Sysinternals SDelete..."
  local SDELETE_URL=https://download.sysinternals.com/files/SDelete.zip
  (cd $TOOLS_DIR && curl -L -o a.zip --retry 5 --retry-all-errors $SDELETE_URL && unzip -o a.zip && rm a.zip)

  # Download KB3138612 to fix Windows Update
  echo "Downloading KB3138612..."
  local KB3138612_URL=https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2016/02/windows6.1-kb3138612-x86_6e90531daffc13bc4e92ecea890e501e807c621f.msu
  (cd $TOOLS_DIR && curl -L -o kb3138612.msu --retry 5 --retry-all-errors $KB3138612_URL)
}


# Display usage
display_usage() {
  echo -e "Usage: $0 [OPTION] NAME USER PASSWORD GUEST_FILES_DIR UPDATE_FILES_DIR WORK_DIR\n"
  echo "Update virtual machine after operating system installation"
  echo "NAME:             Name of VM"
  echo "USER:             Username for VM logon"
  echo "PASSWORD:         Password for VM logon"
  echo "GUEST_FILES_DIR:  Directory with files to copy to VM and run"
  echo "UPDATE_FILES_DIR: Directory with files to copy to VM and run"
  echo "WORK_DIR:         Working dir for intermediate files"
  echo ""
  echo "Options:"
  echo "  -h, --help           display this help and exit"
  echo "  --no-install-wu      don't install Windows Updates Online"
  echo "  --no-install-wu-off  don't install Windows Updates Offline"
  echo "  --no-cleanup         don't cleanup at all"
  echo "  --no-cleanup-dism    don't cleanup using DISM"
  echo "  --no-cleanup-wud     don't cleanup Windows Updates downloads"
  echo "  --no-cleanup-files   don't cleanup various files"
  echo "  --no-cleanmgr        don't use Windows CleanMgr (Disk Cleanup)"
  echo "  --no-zerodisk        don't zero free disk space"
  echo ""
}


### Main code starts here

# Parse options
EXIT_CODE=0
VALID_ARGS=$(getopt -o h --long help,no-install-wu,no-install-wu-off,no-cleanup,no-cleanup-dism,no-cleanup-wud,no-cleanup-files,no-cleanup-cleanmgr,no-zerodisk --name "$0" -- "$@") || EXIT_CODE=$?
if [ $EXIT_CODE != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
eval set -- ${VALID_ARGS}

# Set initial values
OPT_NO_INSTALL_WU=0
OPT_NO_INSTALL_WU_OFF=0
OPT_NO_CLEANUP=0
OPT_NO_CLEANUP_DISM=0
OPT_NO_CLEANUP_WUD=0
OPT_NO_CLEANUP_FILES=0
OPT_NO_CLEANUP_CLEANMGR=0
OPT_NO_ZERODISK=0

# extract options and arguments into variables
while true ; do
  case "$1" in
    -h | --help)
      display_usage
      exit 0
      ;;
    --no-install-wu)
      OPT_NO_INSTALL_WU=1
      shift
      ;;
    --no-install-wu-off)
      OPT_NO_INSTALL_WU_OFF=1
      shift
      ;;
    --no-cleanup)
      OPT_NO_CLEANUP=1
      shift
      ;;
    --no-cleanup-dism)
      OPT_NO_CLEANUP_DISM=1
      shift
      ;;
    --no-cleanup-wud)
      OPT_NO_CLEANUP_WUD=1
      shift
      ;;
    --no-cleanup-files)
      OPT_NO_CLEANUP_FILES=1
      shift
      ;;
    --no-cleanup-cleanmgr)
      OPT_NO_CLEANUP_CLEANMGR=1
      shift
      ;;
    --no-zerodisk)
      OPT_NO_ZERODISK=1
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
if [ $# -ne 6 ] ; then
  display_usage
  exit 1
fi

# Read params
VM_NAME=$1
VM_USER=$2
VM_PASSWORD=$3
VM_GUEST_FILES_DIR=$4
VM_UPDATE_FILES_DIR=$5
VM_WORK_DIR=$6


echo "**************************************"
echo "*** Updating VM \"$VM_NAME\" after operating system install"
echo "**************************************"
echo "User: $VM_USER"
echo "Password: $VM_PASSWORD"
echo "Guest files dir: $VM_GUEST_FILES_DIR"
echo "Update files dir: $VM_UPDATE_FILES_DIR"
echo "Work dir: $VM_WORK_DIR"
echo ""
VM_GUEST_PARAMS=()
if [ "$OPT_NO_INSTALL_WU" -ne 0 ] ; then
  echo "Don't install Windows Updates Online"
  VM_GUEST_PARAMS+=(NO_INSTALL_WU)
fi
if [ "$OPT_NO_INSTALL_WU_OFF" -ne 0 ] ; then
  echo "Don't install Windows Updates Offline"
  VM_GUEST_PARAMS+=(NO_INSTALL_WU_OFF)
fi
if [ "$OPT_NO_CLEANUP_DISM" -ne 0 ] || [ "$OPT_NO_CLEANUP" -ne 0 ] ; then
  echo "Don't cleanup using DISM"
  VM_GUEST_PARAMS+=(NO_CLEANUP_DISM)
fi
if [ "$OPT_NO_CLEANUP_WUD" -ne 0 ] || [ "$OPT_NO_CLEANUP" -ne 0 ] ; then
  echo "Don't cleanup downloaded Windows Updates in SoftwareDistribution dir"
  VM_GUEST_PARAMS+=(NO_CLEANUP_WUD)
fi
if [ "$OPT_NO_CLEANUP_FILES" -ne 0 ] || [ "$OPT_NO_CLEANUP" -ne 0 ] ; then
  echo "Don't cleanup various files"
  VM_GUEST_PARAMS+=(NO_CLEANUP_FILES)
fi
if [ "$OPT_NO_CLEANUP_CLEANMGR" -ne 0 ] || [ "$OPT_NO_CLEANUP" -ne 0 ] ; then
  echo "Don't use Windows CleanMgr"
  VM_GUEST_PARAMS+=(NO_CLEANMGR)
fi
if [ "$OPT_NO_ZERODISK" -ne 0 ] ; then
  echo "Don't zero free diskspace"
  VM_GUEST_PARAMS+=(NO_ZERODISK)
fi

# Create work dir if required
if [ ! -d $VM_WORK_DIR ] ; then
  mkdir -p $VM_WORK_DIR
fi
echo "Copying guest files from \"$VM_GUEST_FILES_DIR\" to \"$VM_WORK_DIR\"..."
cp "$VM_GUEST_FILES_DIR"/* "$VM_WORK_DIR/" || true
echo "Copying update files from \"$VM_UPDATE_FILES_DIR\" to \"$VM_WORK_DIR\"..."
cp "$VM_UPDATE_FILES_DIR"/* "$VM_WORK_DIR/" || true

# Download tools for setup
#downloadTools $VM_WORK_DIR

# Startup VM
echo "Starting VM \"$VM_NAME\"..."
VBoxManage startvm $VM_NAME --type headless
waitUntilVmStartupComplete $VM_NAME

# Run update
echo "Copying update files from \"$VM_WORK_DIR\" to VM..."
VBoxManage guestcontrol $VM_NAME mkdir --parents --username=$VM_USER --password=$VM_PASSWORD "C:\\temp\\work" || echo "Ignoring error"
VBoxManage guestcontrol $VM_NAME copyto --username=$VM_USER --password=$VM_PASSWORD --target-directory "C:\\Temp\\work" $VM_WORK_DIR

echo "Running update script..."
UPDATE_SCRIPT_FINISHED=0
MAX_UPDATE_LOOPS=20
while [ $UPDATE_SCRIPT_FINISHED -eq 0 ]
do
  # Abort after maximum of update loops has been reached
  ((MAX_UPDATE_LOOPS--))
  if [ $MAX_UPDATE_LOOPS -eq 0 ] ; then
    echo "Exceeded max update loops"
    exit 1
  fi

  # Run script
  echo "Running run_update.bat ($MAX_UPDATE_LOOPS runs left before abort)"
  EXIT_CODE=0
  VBoxManage guestcontrol $VM_NAME run --username=$VM_USER --password=$VM_PASSWORD --exe cmd.exe -- /c "C:\\Temp\\work\\run_update.bat" ${VM_GUEST_PARAMS[@]} || EXIT_CODE=$?
  echo "Script returned $EXIT_CODE (VBoxManage adds 32 to non-zero script exit codes)"
  case "$EXIT_CODE" in
  0) # Script exit code 0: Success, update finished
    echo "Success, update finished"
    UPDATE_SCRIPT_FINISHED=1
    ;;
  34)  # Script exit code 2: Reboot VM and re-run update script
    echo "Reboot VM and re-run update script"
    # Wait for VM shutdown
    waitUntilVmStopped $VM_NAME
    # Startup VM again
    echo "Starting VM ..."
    VBoxManage startvm $VM_NAME --type headless
    waitUntilVmUserLoggedIn $VM_NAME
    ;;
  35)  # Script exit code 3: Re-run update script
    echo "Re-run update script"
    ;;
  *) # Treat all other exit codes as error
    echo "Script error occurred"
    exit 1
    ;;
  esac

done

# Cleanup
if [ "$OPT_NO_CLEANUP_FILES" -eq 0 ] ; then
  echo "Removing files from VM"
  VBoxManage guestcontrol $VM_NAME run --username=$VM_USER --password=$VM_PASSWORD --exe reg.exe -- delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v on_login_vbx /f || true
  VBoxManage guestcontrol $VM_NAME rmdir --username=$VM_USER --password=$VM_PASSWORD --recursive "C:\\Temp"
else
  echo "Debug mode: Skip removing files from VM"
fi

# Shutdown VM
echo "Shutting down VM..."
stopVmViaPowerButton $VM_NAME

echo "Done updating VM"