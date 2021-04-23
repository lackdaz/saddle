#!/bin/bash -v                                                                                                                 

# Copy the original raspbian image (which starts 2020...) to a new 
# building image as we're working on it.                                                                               cp 2020*.img building.img                                                                                                                    
                             
# Find partitions on this image and make them available to the 
# build server.                                                 
losetup --find -P vanilla.img
# In the next two steps, we're going to mount the boot partition, then the root partition. They'll be temporarily mounted in $MNT_DIR
MNT_DIR=/mnt/myraspbian
# Mount the boot partition, and copy config.txt (that you need 
# to create) there. If you don't want to customize config.txt
# then you can delete the next few lines                                                                                                   
mkdir -p $MNT_DIR                                                                                           
mount /dev/loop0p1 $MNT_DIR                                                     
cp config.txt $MNT_DIR/
umount $MNT_DIR                                                                 
                       
# Mount the root partition, and copy any files from filesToAdd                                                        
# to the partition. 
mount /dev/loop0p2 $MNT_DIR                                   
cp -r files_to_add/* $MNT_DIR/                  
umount $MNT_DIR                                                                 
# Don't need the loopback device anymore, disconnect it.                                                                                
losetup -D                                                                      
                 
# Finished building the image!                                                             
mv building.img myraspbian.img 

