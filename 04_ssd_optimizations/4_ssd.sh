#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ask if disk is an ssd, otherwise quit

read -p "Is your disk an ssd, otherwise it is not recommended to run this script (y/n)?" CONT
if [ "$CONT" == "y" ]
then
echo "continuing script..."


###
### SSD
###

echo "SSD"

# disable hibernation (speeds up entering sleep mode)
sudo pmset -a hibernatemode 0

# remove the sleep image file to save disk space
sudo rm -rf /private/var/vm/sleepimage

# create a zero-byte file instead
sudo touch /private/var/vm/sleepimage

# and make sure it can be rewritten
sudo chflags uchg /private/var/vm/sleepimage

# disable the sudden motion sensor as it is not useful for SSDs
sudo pmset -a sms 0

echo "done"

else
echo "this script is only for ssds... exiting..."
fi