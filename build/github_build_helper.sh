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


# Display usage
display_usage() {
  echo -e "Usage: $0 [<general-option>] <command>\n"
  echo "General Options:"
  echo "  -h, --help          display this help and exit"
  echo ""
  echo "Commands:"
  echo ""
  echo "  configure-vmware-fusion [OPTION]"
  echo "  Configure VMware Fusion for use in Github Actions environment"
  echo ""
  echo "  Options for configure-vmware-fusion:"
  echo "    -s, --serial-no=SERIAL   serial number for VMware Fusion"
  #echo ""
  #echo "  command2 [OPTION] PARAM2"
  #echo "  Some sample command"
  #echo "    PARAM2:     demo param"
  #echo ""
  #echo "  Options for command2:"
  #echo "    --opt2     Option 2"
  echo ""
}

# Register VMware Fusion serial number
register_vmware_fusion_serial_no() {
  local SERIAL_NO=$1
  local VMFUSION_INIT_TOOL="/Applications/VMware Fusion.app/Contents/Library/Initialize VMware Fusion.tool"

  echo "Register VMware fusion serial number"
  
  if [ "$SERIAL_NO" == "" ] ; then
    # No serial no given => extract trial serial no from application
    echo "Extract trial serial no"
    local SERIAL_LIST=($(strings "/Applications/VMware Fusion.app/Contents/MacOS/VMware Fusion" -10 | egrep -i "^([0-9A-Z]{5}-){4}[0-9A-Z]{5}$"))
    for SERIAL_NO in "${SERIAL_LIST[@]}" ; do
      echo "Trying serial no: $SERIAL_NO"
      EXIT_CODE=0
      sudo "$VMFUSION_INIT_TOOL" set "" "" "$SERIAL_NO" || EXIT_CODE=$?
      if [ $EXIT_CODE -eq 0 ] ;  then
        echo "Success"
        exit 0
      else
        echo "Serial no not accepted"
      fi
    done
    exit 1
  else
    # Registering using given serial number
    echo "Registering using serial no: $SERIAL_NO"
    EXIT_CODE=0
    sudo "$VMFUSION_INIT_TOOL" set "" "" "$SERIAL_NO" || EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ] ;  then
      echo "Success"
      exit 0
    else
      echo "Serial no not accepted"
    fi
  fi
}

# Process command "configure-vmware-fusion"
cmd_configure_vmware_fusion() {(
  set -euo pipefail
  trap 'failure ${LINENO} "$BASH_COMMAND"' ERR
  
  EXIT_CODE=0
  VALID_ARGS=$(getopt -o s: --long serial-no: --name "$0" -- "$@") || EXIT_CODE=$?
  if [ $EXIT_CODE != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
  eval set -- ${VALID_ARGS}

  # Set initial values
  OPT_SERIAL_NO=
  
  # extract options and arguments into variables
  while true ; do
    case "$1" in
      -s | --serial-no)
        OPT_SERIAL_NO="$2"
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
  if [ $# -ne 0 ] ; then
    display_usage
    exit 1
  fi

  echo "Configure VMware Fusion for use in Github Actions environment"
  if [ "$OPT_SERIAL_NO" != "" ] ; then
    echo "Serial no: $OPT_SERIAL_NO"
  fi
  register_vmware_fusion_serial_no "$OPT_SERIAL_NO"
)}

### Main code starts here

# Check for correct number of arguments
if [ $# -eq 0 ] ; then
  display_usage
  exit 1
fi

# Parse general options
while true ; do
  case "$1" in
    -h | --help)
      display_usage
      exit 0
      ;;
    -*) # error
      >&2 echo "Unsupported general option: $1"
      display_usage
      exit 1
      ;;
    *) # end of general options
      COMMAND=$1
      shift
      break
      ;;
  esac
done

# Parse command
case "$COMMAND" in
  configure-vmware-fusion)
    cmd_configure_vmware_fusion $@
    ;;
  *) # end of general options
    >&2 echo "Unsupported command: $COMMAND"
    display_usage
    exit 1
    ;;
esac

