# Common shell code

# Verify file checksum
verify_checksum() {
  local CHECK_FILE=$1
  local CHECKSUM=$2

  echo "Verifying checksum for $CHECK_FILE"
  local CHECKSUM_FILE=$(mktemp)
  echo "$CHECKSUM  $CHECK_FILE" > $CHECKSUM_FILE
  shasum -c $CHECKSUM_FILE
  local SHASUM_EXITCODE=$?
  rm -f $CHECKSUM_FILE
  if [ $SHASUM_EXITCODE -eq 0 ]
  then
    echo "Checksum OK"
    return 0
  else 
    echo "Checksum MISMATCH for $CHECK_FILE"
    return 1
  fi
}


# Get VM info
getVmInfo() {
  local -n arr=$1
  local VM_NAME=$2
  echo "Retrieving VM info for $VM_NAME..."
  local TMP_STR=$(VBoxManage showvminfo --machinereadable $VM_NAME 2>/dev/null | sed -n "s/^\([^=]\+\)=/arr[\1]=/p")
  if [ "$TMP_STR" == "" ]
  then
    echo "VM not found"
    return 1
  fi
  eval "$TMP_STR" 2>/dev/null || true
}


# Wait for VM shutdown
waitUntilVmStopped() {
  local VM_NAME=$1

  # Get VM info
  local -A VM_INFO
  local EXIT_CODE=0
  getVmInfo VM_INFO $VM_NAME || EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]
  then
    # if VM was not found, we're done
    return 1
  fi

  local MAX_WAIT_LOOPS=60
  while [ "${VM_INFO[VMState]}" != "poweroff" ]
  do
    echo "Waiting for VM $VM_NAME to stop ($MAX_WAIT_LOOPS)..."
    sleep 10
    EXIT_CODE=0
    getVmInfo VM_INFO $VM_NAME || EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]
    then
      # exit in case of error
      return 1
    fi
    let MAX_WAIT_LOOPS--
    if [ $MAX_WAIT_LOOPS -eq 0 ]
    then
      echo "Exceeded max wait loops"
      return 1
    fi
  done
  echo "VM $VM_NAME is stopped (State: ${VM_INFO[VMState]})"
}


# Stop VM via ACPI power button
stopVmViaPowerButton() {
  local VM_NAME=$1
  
  # Get VM info
  local -A VM_INFO
  local EXIT_CODE=0
  getVmInfo VM_INFO $VM_NAME || EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]
  then
    # if VM was not found, we're done
    return 1
  fi
  
  # If VM is running => begin shutdown
  echo "Checking whether VM $VM_NAME is running..."
  if [ "${VM_INFO[VMState]}" == "running" ]
  then
    echo "VM $VM_NAME is running, stopping via ACPI power button..."
    VBoxManage controlvm $VM_NAME acpipowerbutton || exit 1
    waitUntilVmStopped $VM_NAME
  else
    echo -e "VM $VM_NAME not running"
  fi
}