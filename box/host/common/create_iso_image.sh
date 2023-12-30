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
  echo -e "Usage: $0 SOURCE_DIR IMAGE_FILE\n"
  echo -e "Create iso image named IMAGE_FILE from SOURCE_DIR.\n"
}


# Check whether mkisofs is available
is_mkisofs_available() {
  local EXIT_CODE=0
  echo -n "Checking for mkisofs..."
  command -v mkisofs > /dev/null || EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ] ; then
    echo "available"
    return 0
  else
    echo "not available"
    return 1
  fi
}


# Create iso image using mkisofs
create_image_mkisofs() {
  local SOURCE_DIR=$1
  local IMAGE_FILE=$2
  echo "Create iso image using mkisofs..."
  mkisofs -r -J -o $2 $1 || return 1
}


# Check whether hdiutil is available
is_hdiutil_available() {
  local EXIT_CODE=0
  echo -n "Checking for hdiutil..."
  command -v hdiutil > /dev/null || EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ] ; then
    echo "available"
    return 0
  else
    echo "not available"
    return 1
  fi
}


# Create iso image using hdiutil
create_image_hdiutil() {
  local SOURCE_DIR=$1
  local IMAGE_FILE=$2
  echo "Create iso image using hdiutil..."
  hdiutil makehybrid -iso -joliet -o $IMAGE_FILE $SOURCE_DIR || return 1
}


### Main code starts here

# Check for -h or --help
if [[ ($@ == "--help") || $@ == "-h" ]] ; then
  display_usage
  exit 0
fi

# Check for correct number of arguments
if [ $# -ne 2 ] ; then
  display_usage
  exit 1
fi

# Read params
SOURCE_DIR=$1
IMAGE_FILE=$2

echo "Create iso image"
echo "  Source dir: $SOURCE_DIR"
echo "  Image file: $IMAGE_FILE"

# Usa available tools
if is_hdiutil_available ; then
  create_image_hdiutil $SOURCE_DIR $IMAGE_FILE
elif is_mkisofs_available ; then
  create_image_mkisofs $SOURCE_DIR $IMAGE_FILE
else
  echo "Error: No supported tool for creating iso images found."
  return 1
fi

echo "Finished creating iso image."
