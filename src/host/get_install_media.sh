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

# Display usage
display_usage() {
  echo -e "Usage: $0 SOURCE_URL DEST_FILE CHECKSUM_SHA1\n"
  echo "Download install media from SOURCE_URL and save it to local file DEST_FILE."
  echo "Check file integrity using given SHA1 checksum CHECKSUM_SHA1."
  echo -e "Don't download file if it already exists and checksum matches.\n"
}


### Main code starts here

# Check for -h or --help
if [[ ($@ == "--help") || $@ == "-h" ]]
then
  display_usage
  exit 0
fi

# Check for correct number of arguments
if [ $# -ne 3 ]
then
  display_usage
  exit 1
fi

# Read params
DOWNLOAD_URL=$1
DOWNLOAD_FILE=$2
SHA1_CHECKSUM=$3

echo "Get install media"
echo "  Download URL:       $DOWNLOAD_URL"
echo "  Install media file: $DOWNLOAD_FILE"
echo "  SHA1 Checksum:      $SHA1_CHECKSUM"

# Check for existing install media
echo -e "\nChecking for local install media file..."
DOWNLOAD_REQUIRED=1
if [ -f "$DOWNLOAD_FILE" ]
then
  # Found local install media file, need to verify checksum
  echo "Local install media file exists: $DOWNLOAD_FILE"

  CHECK_RESULT=0
  verify_checksum $DOWNLOAD_FILE $SHA1_CHECKSUM || CHECK_RESULT=$?

  if [ $CHECK_RESULT -ne 0 ]
  then
    echo "Checksum ERROR => download required"
    echo "Removing corrupted file $DOWNLOAD_FILE"
    rm -f $DOWNLOAD_FILE
  else
    echo "Checksum OK => no download required"
    DOWNLOAD_REQUIRED=0
  fi
else
  echo "Local install media not found => download required"
fi

# Do we need to download?
if [ $DOWNLOAD_REQUIRED -ne 0 ]
then
  DOWNLOAD_DIR=$(dirname $DOWNLOAD_FILE)
  if [ ! -d $DOWNLOAD_DIR ]
  then
    echo "Create download dir $DOWNLOAD_DIR"
    mkdir $DOWNLOAD_DIR
  fi
  echo "Downloading install media from $DOWNLOAD_URL"
  curl -L -o $DOWNLOAD_FILE $DOWNLOAD_URL

  CHECK_RESULT=0
  verify_checksum $DOWNLOAD_FILE $SHA1_CHECKSUM || CHECK_RESULT=$?
  if [ $CHECK_RESULT -ne 0 ]
  then
    echo "Checksum ERROR => giving up"
    exit 1
  fi
fi

echo "Finished getting install media."
