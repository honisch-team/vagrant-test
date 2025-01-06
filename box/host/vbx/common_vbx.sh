# Common shell code

# Get VM info
getVmInfo() {
  local -n arr=$1
  local VM_NAME=$2
  local VM_SHOULD_EXIST=${3:-0}
  echo "Retrieving VM info for \"$VM_NAME\"..."
  local TMP_STR=$(VBoxManage showvminfo --machinereadable $VM_NAME)
  local VBOXMANAGE_ERROR_CODE=$?
  local TMP_STR_2=$(echo "$TMP_STR" | sed -n "s/^\([^=]\+\)=/arr[\1]=/p")
  if [ "$TMP_STR_2" == "" ] ; then
    echo "VM not found"

    if [ $VM_SHOULD_EXIST -ne 0 ] ;  then
      echo "Debug VBoxManage exit code: $VBOXMANAGE_ERROR_CODE"
      echo "Debug TMP_STR begin"
      echo "$TMP_STR"
      echo "Debug TMP_STR end"
    fi
    return 1
  fi
  eval "$TMP_STR_2" 2>/dev/null || true
}


# Wait for VM shutdown
waitUntilVmStopped() {
  local VM_NAME=$1

  # Get VM info
  local -A VM_INFO
  local EXIT_CODE=0
  getVmInfo VM_INFO $VM_NAME || EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ] ; then
    # if VM was not found, we're done
    return 1
  fi

  local MAX_WAIT_LOOPS=60
  while [ "${VM_INFO[VMState]}" != "poweroff" ] ; do
    echo "Waiting for VM \"$VM_NAME\" to stop ($MAX_WAIT_LOOPS)..."
    sleep 10
    EXIT_CODE=0
    getVmInfo VM_INFO $VM_NAME 1 || EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ] ; then
      # in case of error
      return 1
    fi
    ((MAX_WAIT_LOOPS--))
    if [ $MAX_WAIT_LOOPS -eq 0 ] ; then
      echo "Exceeded max wait loops"
      return 1
    fi
  done
  echo "VM \"$VM_NAME\" is stopped (State: ${VM_INFO[VMState]})"
}


# Stop VM via ACPI power button
stopVmViaPowerButton() {
  local VM_NAME=$1

  # Get VM info
  local -A VM_INFO
  local EXIT_CODE=0
  getVmInfo VM_INFO $VM_NAME || EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ] ; then
    # if VM was not found, we're done
    return 1
  fi

  # If VM is running => begin shutdown
  echo "Checking whether VM \"$VM_NAME\" is running..."
  if [ "${VM_INFO[VMState]}" == "running" ] ; then
    echo "VM \"$VM_NAME\" is running, stopping via ACPI power button..."
    VBoxManage controlvm $VM_NAME acpipowerbutton || return 1
    waitUntilVmStopped $VM_NAME
  else
    echo -e "VM \"$VM_NAME\" not running"
  fi
}


# Wait for VM to start up
waitUntilVmStartupComplete() {
  local VM_NAME=$1

  echo "Waiting for startup to complete..."
  VBoxManage guestproperty wait $VM_NAME "/VirtualBox/GuestInfo/OS/NoLoggedInUsers" --timeout 600000 --fail-on-timeout || return 1
  sleep 5
  echo "VM startup complete"
}


# Wait for VM user to login
waitUntilVmUserLoggedIn() {
  local VM_NAME=$1

  echo "Waiting for user to login..."
  VBoxManage guestproperty wait $VM_NAME "vm_user_logon" --timeout 600000 --fail-on-timeout || return 1
  sleep 5
  echo "VM user logged in"
}