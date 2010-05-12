#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

scp gth677b@redondo.gtsav.gatech.edu:~/bench/bench bench
mount -o loop,offset=32256 linux-latest.img vdisk
cp bench vdisk/bench
umount vdisk
scp linux-latest.img gth677b@dumbledore.cc.gatech.edu:~/linux-latest.img
