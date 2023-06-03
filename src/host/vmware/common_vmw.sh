# Common shell code

# Run command in VM
runCommandInVm() {
  local VM_VMX=$1
  shift
  echo $@ > /tmp/$$.job.bat
  echo '@C:\Windows\System32\cmd.exe /c "'C:\\Windows\\Temp\\exec_cmd\\$$.job.bat'" > C:\Windows\Temp\exec_cmd\'$$'.out 2>&1' > /tmp/$$.bat
  vmrun -gu $VM_USER -gp $VM_PASSWORD createDirectoryInGuest $VM_VMX "C:\\Windows\\Temp\\exec_cmd"
  vmrun -gu $VM_USER -gp $VM_PASSWORD CopyFileFromHostToGuest $VM_VMX /tmp/$$.job.bat C:\\Windows\\Temp\\exec_cmd\\$$.job.bat || return 1
  vmrun -gu $VM_USER -gp $VM_PASSWORD CopyFileFromHostToGuest $VM_VMX /tmp/$$.bat C:\\Windows\\Temp\\exec_cmd\\$$.bat || return 1
  vmrun -gu $VM_USER -gp $VM_PASSWORD runProgramInGuest $VM_VMX C:\\Windows\\Temp\\exec_cmd\\$$.bat
  res=$?
  vmrun -gu $VM_USER -gp $VM_PASSWORD CopyFileFromGuestToHost $VM_VMX C:\\Windows\\Temp\\exec_cmd\\$$.out /tmp/$$.out && cat /tmp/$$.out 2>/dev/null
  rm -f /tmp/$$.{out,bat,job.bat}
  vmrun -gu $VM_USER -gp $VM_PASSWORD deleteDirectoryInGuest $VM_VMX "C:\\Windows\\Temp\\exec_cmd"
  if [ $res -gt 0 ] ; then
    res=$(($res + 32))
  fi
  return $res
}


# Get VM state
getVmState() {
  local VM_VMX=$1
  local COUNT=$(vmrun list | grep -c $VM_VMX)
  if [ $COUNT -ne 0 ] ; then
    echo "running"
  else
    echo "stopped"
  fi
}


# Wait for VM shutdown
waitUntilVmStopped() {
  local VM_VMX=$1

  local VM_STATE=$(getVmState $VM_VMX)
  local MAX_WAIT_LOOPS=60
  while [ "$VM_STATE" != "stopped" ] ; do
    # Abort if max wait loops exceeded
    ((MAX_WAIT_LOOPS--))
    if [ $MAX_WAIT_LOOPS -eq 0 ] ; then
      echo "Exceeded max wait loops"
      return 1
    fi

    # Wait for VM to stop
    echo "Waiting for VM to stop ($MAX_WAIT_LOOPS)..."
    sleep 10

    VM_STATE=$(getVmState $VM_VMX)
  done
  echo "VM \"$VM_VMX\" is stopped"
}


# Wait for guestVar to be set
waitForGuestVar() {
  local VM_VMX=$1
  local VAR_NAME=$2

  local MAX_WAIT_LOOPS=360
  echo "Waiting for guest variable \"$VAR_NAME\" to be set in VM ($MAX_WAIT_LOOPS)..."
  while [ true ] ; do
    local EXIT_CODE=0
    local VAR_VALUE=$(vmrun readVariable $VM_VMX guestVar $VAR_NAME) || EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 -a "$VAR_VALUE" != "" ] ; then
      echo "$VAR_NAME: $VAR_VALUE"
      return 0
    fi
    ((MAX_WAIT_LOOPS--))
    if [ $MAX_WAIT_LOOPS -eq 0 ] ; then
      echo "Exceeded max wait loops"
      return 1
    fi
    if [ $(($MAX_WAIT_LOOPS % 10)) -eq 0 ] ; then
      echo "($MAX_WAIT_LOOPS)..."
    fi

    sleep 10
  done
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
  local VM_VMX=$1

  # Trigger VMware tools (otherwise checkToolsState never changes to "running")
  vmrun readVariable $VM_VMX guestVar dummy > /dev/null
  # Get state of VMware tools in guest
  local VM_TOOLS_STATE=$(vmrun checkToolsState $VM_VMX)
  local MAX_WAIT_LOOPS=60
  while [ "$VM_TOOLS_STATE" != "running" ] ; do
    # Abort if max wait loops exceeded
    ((MAX_WAIT_LOOPS--))
    if [ $MAX_WAIT_LOOPS -eq 0 ] ; then
      echo "Exceeded max wait loops"
      return 1
    fi

    # Wait for VM to start up
    echo "Waiting for VM \"$VM_VMX\" to start up ($MAX_WAIT_LOOPS)..."
    sleep 10

    # Trigger VMware tools (otherwise checkToolsState never changes to "running")
    vmrun readVariable $VM_VMX guestVar dummy > /dev/null
    # Get state of VMware tools in guest
    VM_TOOLS_STATE=$(vmrun checkToolsState $VM_VMX)
  done
  sleep 5
  echo "VM startup complete"
}