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
    sudo apt-get update && apt-get install -y pigz
    wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh -O pishrink
    chmod +x pishrink
    sudo mv pishrink /usr/local/bin/
    [[ $(command -v pishrink) ]] && echo "pishrink installed!"
fi

# Copy the original raspbian image to a new
# building image as we're working on it.
sudo ls &>/dev/null

rm -rf build/*

ZIP_EXIST=$(find . -name '*.img' -or -name '*.zip')
echo $ZIP_EXIST
if [[ ! -d "images" ]]; then
    echo "creating images directory"
    mkdir -p images
fi
if [[ -z $ZIP_EXIST ]]; then
    echo "downloading image"
    wget -P images/ https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-03-25/2021-03-04-raspios-buster-armhf-lite.zip
fi
if [[ ! -d "files_to_add" ]]; then
    echo "creating files_to_add directory"
    mkdir -p files_to_add
fi

if [[ ! -d "build" ]]; then
    echo "creating build directory"
    mkdir -p build
fi

SRC_DIR=$(find . -name '*_saddle*' -o -name '*-saddle*')
if [[ -z "$SRC_DIR" ]]; then
    echo "source files not found!"
    echo "Did you add a <*>-saddle folder in files_to_add?"
    exit 1
fi
SRC_DIR=$(realpath $SRC_DIR)

VFAT_DIR=$(find $SRC_DIR -name 'vfat')
if [[ -z "$VFAT_DIR" ]]; then
    echo "vfat files not found!"
    echo "Did you add a vfat folder in tb_saddle?"
    exit 1
fi

VFAT_DIR=$(realpath $VFAT_DIR)

EXT_DIR=$(find $SRC_DIR -name 'ext4')
if [[ -z "$EXT_DIR" ]]; then
    echo "ext4 files not found!"
    echo "Did you add a ext4 folder in tb_saddle?"
    exit 1
fi

EXT_DIR=$(realpath $EXT_DIR)

# TODO: add support for .img format after

IMG_NAME=lite-deploy
MNT_DIR_NAME=pideploy
BUILD_DIR=$(realpath build)
SRC_ZIP=($(realpath images/*.zip))
if [[ ${#SRC_ZIP[@]} -eq 1 ]]; then
    SRC_ZIP=${SRC_ZIP[0]}
elif [[ ${#SRC_ZIP[@]} -gt 1 ]]; then
    echo "More than one zip image found in images directory"
    exit 1
else
    echo "Error with number of images in images directory"
    exit 1
fi

DEST_ZIP="${BUILD_DIR}/${IMG_NAME}.zip"
TMP_DIR=$(realpath /tmp/saddle)
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
sudo cp $VFAT_DIR/ssh.txt $MNT_DIR # copy ssh file to automagically enable SSH
sudo umount $MNT_DIR

# Mount the root partition, and copy any files from ext4 to the partition.
sudo mount ${LOOP_GLOB}p2 $MNT_DIR # I don't know why its 19
sudo cp -r ${EXT_DIR}/* $MNT_DIR/
sudo umount $MNT_DIR
# Don't need the loopback device anymore, disconnect it.
sudo losetup -D

# Finished building the image!
# sudo cp $SRC_IMG ${BUILD_DIR}/${IMG_NAME}.img
sudo pishrink -vraz $SRC_IMG $DEST_ZIP
# zip -v $DEST_ZIP $SRC_IMG
sudo rm -rf $TMP_DIR

# main "$@" # --> $@ is for command line arguments

exit 0 # --> needed or it tries to read modified files when main exits
