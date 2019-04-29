#!/bin/bash


## Code modified to test git ###


### This comment added in the test branch of git.
### Add a new comment to the test branch ##### 


SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

imagefile=$1
echo "image file is $imagefile"
mountpath="/home/penfold/work/Firmware/mount/mount"
count=0


for startsector in $(sfdisk -d $imagefile | awk '/: start=/{gsub(/\,/,"");print $6}'); do

  mountdir=$mountpath${count}
  [ -d $mountdir ] || mkdir -p $mountdir
  mount $imagefile $mountdir  -o loop,offset=$((512*${startsector}))
  count=$((count+1))

  echo "Mounting $imagefile from start sector $startsector on $mountdir"

done

## mount and associat loop device in one command.
## sudo mount vibe-usb.image ./mount/mount1 -o loop,offset=$((512*2048))

IFS=$SAVEIFS

