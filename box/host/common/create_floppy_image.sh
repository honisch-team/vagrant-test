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
  echo -e "Create floppy image named IMAGE_FILE from SOURCE_DIR.\n"
}


# Check whether mtools is available
is_mtools_available() {
  local EXIT_CODE=0
  echo -n "Checking for mtools..."
  command -v mtools > /dev/null || EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ] ; then
    echo "available"
    return 0
  else
    echo "not available"
    return 1
  fi
}


# Create floppy image using mtools
create_image_mtools() {
  local SOURCE_DIR=$1
  local IMAGE_FILE=$2
  echo "Create floppy image using mtools..."
  dd bs=512 count=2880 if=/dev/zero of=$2 || return 1
  mformat -i $2 -f 1440 :: || return 1
  mcopy -i $2 -vs $SOURCE_DIR/* :: || return 1
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


# Create floppy image using hdiutil
create_image_hdiutil() {
  local SOURCE_DIR=$1
  local IMAGE_FILE=$2
  echo "Create floppy image using hdiutil..."

  # hdiutil always creates floppy image file as *.dmg
  local IMAGE_FILE_DMG=$2.dmg
  hdiutil create -size 1440k -fs "MS-DOS FAT12" -layout NONE -srcfolder "$SOURCE_DIR" -format UDRW -ov "$IMAGE_FILE" || return 1

  # Rename floppy image file to original name
  mv "$IMAGE_FILE_DMG" "$IMAGE_FILE" || return 1
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

echo "Create floppy image"
echo "  Source dir: $SOURCE_DIR"
echo "  Image file: $IMAGE_FILE"

# Usa available tools
if is_hdiutil_available ; then
  create_image_hdiutil $SOURCE_DIR $IMAGE_FILE
elif is_mtools_available ; then
  create_image_mtools $SOURCE_DIR $IMAGE_FILE
else
  echo "Error: No supported tool for creating floppy images found."
  exit 1
fi

echo "Finished creating floppy image."
