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