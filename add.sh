#!/bin/bash

# Copyright (c) 2021, Seth Loh github.com/lackdaz
# All rights reserved by TelemedC Pte Ltd.
set -e

## EXIT CATCH ##
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?." && sudo losetup -D' EXIT

# Look for and install pishrink
if [[ ! $(command -v pishrink) ]]; then
    # install pishrink
    wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh -O pishrink
    chmod +x pishrink
    sudo mv pishrink /usr/local/bin/
    [[ $(command -v pishrink) ]] && echo "pishrink installed!"
fi

# Copy the original raspbian image to a new
# building image as we're working on it.
sudo ls images &>/dev/null

rm -rf build/*

IMG_NAME=lite-deploy
MNT_DIR_NAME=pideploy
BUILD_DIR=$(realpath build)
SRC_ZIP=$(realpath images/lite-vanilla.zip)
DEST_ZIP="${BUILD_DIR}/${IMG_NAME}.zip"
TMP_DIR=$(realpath /tmp)
sudo unzip -o $SRC_ZIP -d $TMP_DIR
SRC_IMG=${TMP_DIR}/*.img

[[ -z "$SRC_IMG" ]] && echo "source image not found!" && exit 1
# TODO: log error
echo "source image: $SRC_IMG"

# Find partitions on this image and make them available to the
# build server.
sudo losetup --find -P $SRC_IMG

# find the loop glob
LOOP_GLOB=$(ls /dev/loop* | grep loop[0-9]*p[1]$)
LOOP_GLOB=$(echo $LOOP_GLOB | cut -c 1-$((${#LOOP_GLOB} - 2)))
if [[ ${#LOOP_GLOB[@]} -gt 1 ]]; then
    echo "Error: too many partitions mounted. Unmounting..."
    sudo umount $MNT_DIR
    sudo losetup -D
    exit 1
fi
echo "found ${#LOOP_GLOB[@]} partition glob: ${LOOP_GLOB}"
# In the next two steps, we're going to mount the boot partition, then the root partition. They'll be temporarily mounted in $MNT_DIR
MNT_DIR=/mnt/${MNT_DIR_NAME}
# Mount the boot partition, and copy config.txt (that you need
# to create) there. If you don't want to customize config.txt
# then you can delete the next few lines
sudo mkdir -p $MNT_DIR
sudo mount ${LOOP_GLOB}p1 $MNT_DIR
# sudo cp config.txt $MNT_DIR/
sudo umount $MNT_DIR

# Mount the root partition, and copy any files from filesToAdd
# to the partition.
sudo mount ${LOOP_GLOB}p2 $MNT_DIR # I don't know why its 19
sudo cp -r files_to_add/* $MNT_DIR/
sudo umount $MNT_DIR
# Don't need the loopback device anymore, disconnect it.
sudo losetup -D

# Finished building the image!
sudo cp $SRC_IMG ${BUILD_DIR}/${IMG_NAME}.img
sudo pishrink -vraz $SRC_IMG $DEST_ZIP
# zip -v $DEST_ZIP $SRC_IMG
sudo rm -rf $TMP_DIR

# main "$@" # --> $@ is for command line arguments

exit 0 # --> needed or it tries to read modified files when main exits
