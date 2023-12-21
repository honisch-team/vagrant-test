# Common shell code

# Check if Vagrant box is installed
isBoxInstalled() {
  local BOX_NAME=$1
  echo "Checking if box \"$BOX_NAME\" is installed..."
  local BOX_INSTALLED=$(vagrant box list --machine-readable | grep -c ",box-name,test-box$")
  if [ $BOX_INSTALLED -eq 0 ] ; then
    echo "Box $BOX_NAME is NOT installed"
    return 1
  fi
  echo "Box $BOX_NAME IS installed"
  return 0
}


# Remove installed Vagrant box
removeBox() {
  local BOX_NAME=$1

  # Check if box is installed
  isBoxInstalled $BOX_NAME || return 1

  echo "Removing box \"$BOX_NAME\"..."
  local EXIT_CODE=0
  vagrant box remove $BOX_NAME || EXIT_CODE=$?
  return $EXIT_CODE
}


# Destroy Vagrant box instance
destroyBox() {
  local TEST_DIR=$1

  echo "Checking for test environment \"$TEST_DIR\"..."
  # Check for environment dir
  if [ ! -d $TEST_DIR ] ; then
    echo "Test environment not found"
    return 1
  fi

  # Check for Vagrantfile
  if [ ! -f $TEST_DIR/Vagrantfile ] ; then
    echo "Test environment not valid"
    return 1
  fi

  # Destroy box instances
  echo "Destroying box instance..."
  (cd $TEST_DIR && vagrant destroy --force)

  # Remove files
  (shopt -s dotglob && rm -rf $TEST_DIR/*)
}


# Start box
start_box() (
  set -euo pipefail
  local VG_DIR=$1
  local VG_DEBUG_LOG=$2
  local VG_UP_PARAMS=${3:-}

  # Change to vagrant dir
  cd $VG_DIR

  local MAX_ATTEMPTS=10
  echo "****************"
  echo "*** Starting vagrant box"
  echo "****************"
  local EXIT_CODE=0

  # Create log dir if necessary
  if [ ! -z "$VG_DEBUG_LOG" ] ; then
    local LOG_DIR=$(dirname $VG_DEBUG_LOG)
    if [ ! -d $LOG_DIR ] ; then
      mkdir -p $LOG_DIR
    fi
  fi

  # Launch box, try multiple times due to issue with vmware_desktop provider
  while [ $MAX_ATTEMPTS -gt 0 ] ; do
    ((MAX_ATTEMPTS--))
    EXIT_CODE=0

    if [ -z "$VG_DEBUG_LOG" ] ; then
      vagrant up $VG_UP_PARAMS || EXIT_CODE=$?
    else
      vagrant up --debug $VG_UP_PARAMS 2>> "$VG_DEBUG_LOG" || EXIT_CODE=$?
    fi

    # Exit if launch successful
    if [ $EXIT_CODE -eq 0 ] ; then
      return 0
    fi

    # On failure: Sleep and retry
    echo "Starting vagrant box failed, $MAX_ATTEMPTS attempts left"
    sleep 10
  done

  # Giving up, return error code
  return $EXIT_CODE
)
