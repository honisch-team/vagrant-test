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
  echo "configure-vmware-fusion [OPTION]"
  echo "  Configure VMware Fusion for use in Github Actions environment"
  echo ""
  echo "  Options for configure-vmware-fusion:"
  echo "    -s, --serial-no=SERIAL   serial number for VMware Fusion"
  echo ""
  echo "install-build-tools VIRT_PROVIDER RUNNER_OS WORKFLOW"
  echo "  Install build tools on Github hosted runner"
  echo "    VIRT_PROVIDER: Virtualization provider (vbx,vmw)"
  echo "      vbx=Virtualbox, vmw=VMware (Workstation on Linux or Fusion on MacOS)"
  echo "    RUNNER_OS:     Runner operating system (Linux,macOS)"
  echo "    WORKFLOW:      build or test"
  echo ""
}


# Install build tools for MacOS runner
install_build_tools_macos_runner() {
  local VIRT_PROVIDER=$1
  local WORKFLOW=$2

  case "$VIRT_PROVIDER" in
    vbx)
      # Nothing to do, VirtualBox should already be installed
      ;;
    vmw)
      # Install and configure VMware Fusion
      echo "*** Installing VMware Fusion"
      brew install --cask vmware-fusion || exit $?

      echo "*** Configuring VMware Fusion"
      register_vmware_fusion_serial_no "" || exit $?

      # Install tools for test workflow
      if [ "$WORKFLOW" = "test" ] ; then
        echo "*** Installing Vagrant VMware utility"
        brew install --cask vagrant-vmware-utility || exit $?

        echo "*** Installing Vagrant Plugin vagrant-vmware-desktop"
        vagrant plugin install vagrant-vmware-desktop || exit $?
      fi
      ;;
    *) # error
      >&2 echo "Error: Unsupported virtualization provider: $VIRT_PROVIDER"
      display_usage
      exit 1
      ;;
  esac
}


# Install VMware Workstation
install_vmware_workstation() {
  local VIRT_PROVIDER=$1

  # Set  VMware Workstation version to 17 if not set
  if [[ -z "${VMWARE_WORKSTATION_VERSION-}" ]]; then
    VMWARE_WORKSTATION_VERSION=17
  fi

  case "$VMWARE_WORKSTATION_VERSION" in
    17)
      # VMware Workstation 17
      echo "*** Downloading VMware Workstation 17"
      local INSTALLER_NAME=VMware-Workstation-17.6.2-24409262.x86_64.bundle
      local TOOLS_WINDOWS_NAME=vmware-tools-windows-12.4.5-23787635.x86_64.component
      local DOWNLOAD_URL_PREFIX=https://softwareupdate.vmware.com/cds/vmw-desktop/ws/17.6.2/24409262/linux

      local DOWNLOAD_URL_INSTALLER=$DOWNLOAD_URL_PREFIX/core/$INSTALLER_NAME.tar
      local DOWNLOAD_URL_TOOLS_WINDOWS=$DOWNLOAD_URL_PREFIX/packages/$TOOLS_WINDOWS_NAME.tar

      # Download installer
      echo "*** Downloading VMware Workstation installer from $DOWNLOAD_URL_INSTALLER"
      curl -L --retry 5 $DOWNLOAD_URL_INSTALLER | tar -xvf - $INSTALLER_NAME || exit $?
      chmod a+x $INSTALLER_NAME || exit $?

      # Download VMware tools for Windows
      echo "*** Downloading VMware Tools for Windows from $DOWNLOAD_URL_TOOLS_WINDOWS"
      curl -L --retry 5 $DOWNLOAD_URL_TOOLS_WINDOWS | tar -xvf - $TOOLS_WINDOWS_NAME || exit $?

      # Install VMware Workstation
      echo "*** Installing VMware Workstation"
      sudo ./$INSTALLER_NAME --console --required --eulas-agreed --install-component $TOOLS_WINDOWS_NAME || exit $?

      # Configure VMware modules
      echo "*** vmware-modconfig"
      sudo /usr/bin/vmware-modconfig --console --install-all || true
      ;;
    16)
      # VMware Workstation 16
      echo "*** Downloading VMware Workstation 16"
      local INSTALLER_NAME=VMware-Workstation-16.2.5-20904516.x86_64.bundle
      local TOOLS_WINDOWS_NAME=vmware-tools-windows-11.3.5-18557794.x86_64.component
      local DOWNLOAD_URL_PREFIX=https://softwareupdate.vmware.com/cds/vmw-desktop/ws/16.2.5/20904516/linux

      local DOWNLOAD_URL_INSTALLER=$DOWNLOAD_URL_PREFIX/core/$INSTALLER_NAME.tar
      local DOWNLOAD_URL_TOOLS_WINDOWS=$DOWNLOAD_URL_PREFIX/packages/$TOOLS_WINDOWS_NAME.tar

      # Download installer
      echo "*** Downloading VMware Workstation installer from $DOWNLOAD_URL_INSTALLER"
      curl -L --retry 5 $DOWNLOAD_URL_INSTALLER | tar -xvf - $INSTALLER_NAME || exit $?
      chmod a+x $INSTALLER_NAME || exit $?

      # Download VMware tools for Windows
      echo "*** Downloading VMware Tools for Windows from $DOWNLOAD_URL_TOOLS_WINDOWS"
      curl -L --retry 5 $DOWNLOAD_URL_TOOLS_WINDOWS | tar -xvf - $TOOLS_WINDOWS_NAME || exit $?

      # Install VMware Workstation
      echo "*** Installing VMware Workstation"
      sudo ./$INSTALLER_NAME --console --required --eulas-agreed --install-component $TOOLS_WINDOWS_NAME || exit $?

      # Register VMware Workstation
      echo "*** Registering VMware Workstation"
      register_vmware_workstation_serial_no "" "15.0+" || exit $?

      # Workaround for building kernel modules
      echo "*** Installing kernel modules by workaround"
      local HOST_MODULES_TAG=w16.2.5
      curl -L -o vmware-host-modules-$HOST_MODULES_TAG.tar.gz https://github.com/mkubecek/vmware-host-modules/archive/refs/tags/$HOST_MODULES_TAG.tar.gz || exit $?
      tar xzvf vmware-host-modules-$HOST_MODULES_TAG.tar.gz || exit $?
      cd vmware-host-modules-$HOST_MODULES_TAG
      make || exit $?
      sudo make install || exit $?
      sudo systemctl restart vmware.service || exit $?
      ;;
    15)
      # VMware Workstation 15
      echo "*** Downloading VMware Workstation 15"
      local INSTALLER_NAME=VMware-Workstation-15.5.7-17171714.x86_64.bundle
      local TOOLS_WINDOWS_NAME=vmware-tools-windows-11.0.6-15940789.x86_64.component
      local DOWNLOAD_URL_PREFIX=https://softwareupdate.vmware.com/cds/vmw-desktop/ws/15.5.7/17171714/linux

      local DOWNLOAD_URL_INSTALLER=$DOWNLOAD_URL_PREFIX/core/$INSTALLER_NAME.tar
      local DOWNLOAD_URL_TOOLS_WINDOWS=$DOWNLOAD_URL_PREFIX/packages/$TOOLS_WINDOWS_NAME.tar

      # Download installer
      echo "*** Downloading VMware Workstation installer from $DOWNLOAD_URL_INSTALLER"
      curl -L --retry 5 $DOWNLOAD_URL_INSTALLER | tar -xvf - $INSTALLER_NAME || exit $?
      chmod a+x $INSTALLER_NAME || exit $?

      # Download VMware tools for Windows
      echo "*** Downloading VMware Tools for Windows from $DOWNLOAD_URL_TOOLS_WINDOWS"
      curl -L --retry 5 $DOWNLOAD_URL_TOOLS_WINDOWS | tar -xvf - $TOOLS_WINDOWS_NAME || exit $?

      # Install VMware Workstation
      echo "*** Installing VMware Workstation"
      sudo ./$INSTALLER_NAME --console --required --eulas-agreed --install-component $TOOLS_WINDOWS_NAME || exit $?

      # Register VMware Workstation
      echo "*** Registering VMware Workstation"
      register_vmware_workstation_serial_no "" "15.0+" || exit $?

      # Workaround for building kernel modules
      echo "*** Installing kernel modules by workaround"
      local HOST_MODULES_TAG=w15.5.7-k5.19
      curl -L -o vmware-host-modules-$HOST_MODULES_TAG.tar.gz https://github.com/mkubecek/vmware-host-modules/archive/refs/tags/$HOST_MODULES_TAG.tar.gz || exit $?
      tar xzvf vmware-host-modules-$HOST_MODULES_TAG.tar.gz || exit $?
      cd vmware-host-modules-$HOST_MODULES_TAG
      make || exit $?
      sudo make install || exit $?
      sudo systemctl restart vmware.service || exit $?
      ;;
    14)
      # VMware Workstation 14
      echo "*** Downloading VMware Workstation 14"
      local INSTALLER_NAME=VMware-Workstation-14.1.7-12989993.x86_64.bundle
      local TOOLS_WINDOWS_NAME=vmware-tools-windows-10.2.5-8068393.x86_64.component
      local DOWNLOAD_URL_PREFIX=https://softwareupdate.vmware.com/cds/vmw-desktop/ws/14.1.7/12989993/linux/

      local DOWNLOAD_URL_INSTALLER=$DOWNLOAD_URL_PREFIX/core/$INSTALLER_NAME.tar
      local DOWNLOAD_URL_TOOLS_WINDOWS=$DOWNLOAD_URL_PREFIX/packages/$TOOLS_WINDOWS_NAME.tar

      # Download installer
      echo "*** Downloading VMware Workstation installer from $DOWNLOAD_URL_INSTALLER"
      curl -L --retry 5 $DOWNLOAD_URL_INSTALLER | tar -xvf - $INSTALLER_NAME || exit $?
      chmod a+x $INSTALLER_NAME || exit $?

      # Download VMware tools for Windows
      echo "*** Downloading VMware Tools for Windows from $DOWNLOAD_URL_TOOLS_WINDOWS"
      curl -L --retry 5 $DOWNLOAD_URL_TOOLS_WINDOWS | tar -xvf - $TOOLS_WINDOWS_NAME || exit $?

      # Install VMware Workstation
      echo "*** Installing VMware Workstation"
      sudo ./$INSTALLER_NAME --console --required --eulas-agreed --install-component $TOOLS_WINDOWS_NAME || exit $?

      # Register VMware Workstation
      echo "*** Registering VMware Workstation"
      register_vmware_workstation_serial_no "" "14.0+" || exit $?

      # Workaround for building kernel modules
      echo "*** Installing kernel modules by workaround"
      local HOST_MODULES_TAG=w14.1.7-k5.19
      curl -L -o vmware-host-modules-$HOST_MODULES_TAG.tar.gz https://github.com/mkubecek/vmware-host-modules/archive/refs/tags/$HOST_MODULES_TAG.tar.gz || exit $?
      tar xzvf vmware-host-modules-$HOST_MODULES_TAG.tar.gz || exit $?
      cd vmware-host-modules-$HOST_MODULES_TAG
      make || exit $?
      sudo make install || exit $?
      sudo systemctl restart vmware.service || exit $?
      ;;
    *) # error
      >&2 echo "Error: Unsupported VMware Workstation version: $VMWARE_WORKSTATION_VERSION"
      display_usage
      exit 1
      ;;
  esac
}


# Install build tools for Linux runner
install_build_tools_linux_runner() {
  local VIRT_PROVIDER=$1
  local WORKFLOW=$2

  echo "*** Setting up hashicorp apt repository"
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update

  echo "*** Installing mtools"
  sudo apt-get install mtools || exit $?

  echo "*** Installing genisoimage"
  sudo apt-get install genisoimage || exit $?

  case "$VIRT_PROVIDER" in
    vbx)
      # Install VirtualBox
      echo "*** Installing VirtualBox"
      sudo apt-get install virtualbox virtualbox-guest-additions-iso || exit $?

      # Install Vagrant
      echo "*** Installing Vagrant"
      sudo apt-get install vagrant || exit $?
      ;;
    vmw*)
      # Install VMware Workstation
      install_vmware_workstation $VIRT_PROVIDER || exit $?


      # Install Vagrant
      echo "*** Installing Vagrant"
      sudo apt-get install vagrant || exit $?

      # Install tools for test workflow
      if [ "$WORKFLOW" = "test" ] ; then
        echo "*** Installing Vagrant VMware utility"
        sudo apt-get install vagrant-vmware-utility || exit $?

        echo "*** Installing Vagrant Plugin vagrant-vmware-desktop"
        vagrant plugin install vagrant-vmware-desktop || exit $?
      fi
      ;;
    *) # error
      >&2 echo "Error: Unsupported virtualization provider: $VIRT_PROVIDER"
      display_usage
      exit 1
      ;;
  esac
}


# Register VMware Fusion serial number
register_vmware_fusion_serial_no() {
  local SERIAL_NO=$1
  local VMFUSION_INIT_TOOL="/Applications/VMware Fusion.app/Contents/Library/Initialize VMware Fusion.tool"
  local VMFUSION_LICENSE_PATH_PREFIX="/Library/Preferences/VMware Fusion/license-fusion-"

  echo "Register VMware fusion serial number"

  if [ "$SERIAL_NO" == "" ] ; then
    # No serial no given => extract trial serial no from application
    echo "Extract trial serial no"
    local SERIAL_LIST=($(strings "/Applications/VMware Fusion.app/Contents/MacOS/VMware Fusion" -10 | egrep -i "^([0-9A-Z]{5}-){4}[0-9A-Z]{5}$"))
    for SERIAL_NO in "${SERIAL_LIST[@]}" ; do
      echo "Trying serial no: $SERIAL_NO"
      EXIT_CODE=0
      sudo "$VMFUSION_INIT_TOOL" set "" "" "$SERIAL_NO" || EXIT_CODE=$?
      # Check for license file
      echo "Checking whether license file was created ($VMFUSION_LICENSE_PATH_PREFIX...)"
      if ls "$VMFUSION_LICENSE_PATH_PREFIX"* > /dev/null 2>&1; then
        echo "Success"
        return 0
      else
        echo "Serial no not accepted"
      fi
    done
    return 1
  else
    # Registering using given serial number
    echo "Registering using serial no: $SERIAL_NO"
    EXIT_CODE=0
    sudo "$VMFUSION_INIT_TOOL" set "" "" "$SERIAL_NO" || EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ] ;  then
      echo "Success"
      return 0
    else
      echo "Serial no not accepted"
    fi
  fi
}


# Register VMware Workstation serial number
register_vmware_workstation_serial_no() {
  local SERIAL_NO=$1
  local LICENSE_VERSION=$2

  echo "Register VMware workstation serial number"
  local VMWARE_LICENSE_PATH_PREFIX=/etc/vmware/license-ws
  if [ "$SERIAL_NO" == "" ] ; then
    # No serial no given => extract trial serial no from application
    echo "Extract trial serial no"
    local SERIAL_LIST=($(strings -10 "/usr/lib/vmware/lib/libvmwareui.so/libvmwareui.so" | egrep -i "^([0-9A-Z]{5}-){4}[0-9A-Z]{5}$"))
    for SERIAL_NO in "${SERIAL_LIST[@]}" ; do
      echo "Trying serial no: $SERIAL_NO"
      EXIT_CODE=0
      sudo vmware-license-enter.sh "$SERIAL_NO" "VMWare Workstation" $LICENSE_VERSION || EXIT_CODE=$?
      # Check for license file
      echo "Checking whether license file was created ($VMWARE_LICENSE_PATH_PREFIX...)"
      if ls "$VMWARE_LICENSE_PATH_PREFIX"* > /dev/null 2>&1; then
        echo "Success"
        return 0
      else
        echo "Serial no not accepted"
      fi
    done
    return 1
  else
    # Registering using given serial number
    echo "Registering using serial no: $SERIAL_NO"
    EXIT_CODE=0
    sudo vmware-license-enter.sh "$SERIAL_NO" "VMWare Workstation" "15.0+" || EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ] ;  then
      echo "Success"
      return 0
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


# Process command "install-build-tools"
cmd_install_build_tools() {(
  set -euo pipefail
  trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

  # Check for correct number of arguments
  if [ $# -ne 3 ] ; then
    display_usage
    exit 1
  fi

  # Read params
  VIRT_PROVIDER=$1
  RUNNER_OS=$2
  WORKFLOW=$3

  echo "Install build tools for $VIRT_PROVIDER on $RUNNER_OS in workflow $WORKFLOW"

  case "$RUNNER_OS" in
    Linux)
      install_build_tools_linux_runner "$VIRT_PROVIDER" "$WORKFLOW"
      ;;
    macOS)
      install_build_tools_macos_runner "$VIRT_PROVIDER" "$WORKFLOW"
      ;;
    *) # error
      >&2 echo "Error: Unsupported runner OS: $RUNNER_OS"
      display_usage
      exit 1
      ;;
  esac
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
  install-build-tools)
    cmd_install_build_tools $@
    ;;
  *) # end of general options
    >&2 echo "Unsupported command: $COMMAND"
    display_usage
    exit 1
    ;;
esac

